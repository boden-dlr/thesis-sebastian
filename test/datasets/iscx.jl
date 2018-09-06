using Glob
using CSV
using DataFrames
using Statistics
using Random
using LogClustering.Parsing: parse_event_log, Parser, Label
using LogClustering.Sequence: cols, rows
using Plots
gr()
using Clustering
using LogClustering.ClusteringUtils
using LogClustering.Serialize
using DataStructures: OrderedDict
using Dates

include(joinpath(pwd(), "test/models/DeepKATE.jl"))

# A = [1 2 3; 4 5 6]
# Bad = [1 Inf 3; 4 5 NaN]

"""
    normalize columns by their maximum, which clamps the matrix to
    the inverall of [0.0, 1.0].

    NaN gets converted to 0.0
    Inf gets converted to 1.0
"""
function normalize!(M::AbstractMatrix) # by maximum over column

    for i in 1:length(M)
        if isnan(M[i])
            M[i] = 0
        end
        if isinf(M[i])
            M[i] = 1
        end
    end

    maxima = [maximum(M[:,m]) for m in 1:size(M)[2]]

    for m in 1:size(M)[2]
        if maxima[m] > 0
            M[:,m] = M[:,m] ./ maxima[m]
        end
    end

    clamp!(M, 0.0, 1.0)
end


function plot_embedded(data, marker, options, id)

    file_str = Serialize.convert(String, options)

    filename = string(
        "data/experiments/deep-kate/iscx/plot_",
        id, "_",
        file_str, "_clustered_",
        "KATE_sig_KATE50-20-10_sin_sig_sig_sig_drop06_sig_no-repel_scale=max",
        ".png")

    if !isfile(filename)
        fig_str = Serialize.convert(String, options, delim=" ")
        title = string(fig_str[1:floor(Int,end/2)], "\n",
                       fig_str[ceil(Int,end/2):end])

        dim = size(data)[2]
        figure = nothing
        if dim == 2
            figure = scatter(
                data[:,1], data[:,2],
                marker_z = marker,
                title = title)
        else #if dim == 3
            figure = scatter3d(
                data[:,1], data[:,2], data[:,3],
                marker_z = marker,
                title = title)
        end
        # display(figure)
        savefig(figure, filename)
    end
end


function purity(C, L, labels)
    TP = 0
    FP = 0
    for (i,c) in enumerate(C)
        c_ls = zeros(length(labels))
        ls = map(m->L[m], c)

        for l in ls
            c_ls[labels[l]] += 1
        end
        c_label = argmax(c_ls)

        for l in ls
            if labels[l] == c_label
                TP += 1
            else
                FP += 1
            end
        end
    end
    TP, FP
end


function generate_training_ids(
    data::Matrix,
    labels::Vector,
    take::Int,
    train::Function = l -> l == "BENIGN")

    n_samples = size(data)[1]
    @assert take <= n_samples

    i = 0
    ids = Vector{Int}(undef, take)
    while i < take
        r = Random.rand(1:n_samples)
        if train(labels[r])
            i += 1
            ids[i] = r
        end
    end
    ids
end


function to_vec_vec(M::Matrix)
    [r for r in rows(M)]
end


function iscx(M, L, labels, n_outlier, seed, epochs, latent, id, train_rel, test_abs)
    Random.seed!(seed)


    n = size(M)[1]

    @info n, seed, epochs

    # train_ids = Random.rand(1:n, floor(Int, 10)) #0.001*n
    train_ids = generate_training_ids(M,L, floor(Int, train_rel*n))
    # train_ids = [1:floor(Int,train_rel*n)...]

    # test_ids = Random.rand(1:n, 50000)
    # test_ids = setdiff(test_ids, train_ids)
    test_ids = setdiff(1:n, train_ids)[1:min(end, test_abs)]
    # test_ids = test_ids[1:floor(Int, end/2)]
    # test_ids = [1:n...]
    @show length(train_ids), length(test_ids)

    train = to_vec_vec(normalize!(M[train_ids,:]))
    test = to_vec_vec(normalize!(M[test_ids,:])) #[end-19999:end] #
    test_labels = [labels[l] for l in L[test_ids]]

    model = fit_deep_kate(train, seed, latent, epochs, true)

    (embedded, reconstruced) = generate(model, test) # all
    embedded = scale(embedded)

    n_train = length(train_ids)
    n_test  = length(test_ids)

    options = OrderedDict{String,Any}(
        "seed" => seed,
        "n" => n,
        "train" => n_train,
        "test" => n_test,
        "lat" => latent,
        "epo" => epochs)
    plot_embedded(embedded, test_labels, options, id)

    ncs = Vector{Int}()
    tps = Vector{Int}()
    fps = Vector{Int}()
    fp_tps = Vector{Float64}()
    fp_ns = Vector{Float64}()
    fp_n_outs = Vector{Float64}()
    eps = [0.001, 0.01, 0.05, 0.1, 0.15, 0.25, 0.5, 1.0]
    for epsilon in eps #, 1.0, 1.5, 2.0]
        # epsilon = 0.1 # radius
        result = dbscan(embedded', epsilon)
        A = ClusteringUtils.clustering_to_assignments(result)
        C = ClusteringUtils.assignments_to_clustering(A)

        TP, FP = purity(C, L, labels)
        @show TP, FP

        push!(ncs, length(C))
        push!(tps, TP)
        push!(fps, FP)
        push!(fp_tps, FP/TP)
        push!(fp_ns, FP/n_test)
        push!(fp_n_outs, FP/n_outlier)

        options["eps"]  = epsilon
        options["nc"]   = ncs[end]
        options["TP"]   = tps[end]
        options["FP"]   = fps[end]
        options["FPTP"] = fp_tps[end]
        options["FPnc"]  = fp_ns[end]
        options["FPno"]  = fp_n_outs[end]
        plot_embedded(embedded, A, options, id)
    end

    stats_figure = plot(eps, [ncs, tps, fps, fp_tps, fp_ns, fp_n_outs],
             xscale = :log10,
             yscale = :log10,
             shape = :circle,
             labels = ["Nc", "TP", "FP", "FP/TP", "FP/Nc", "FP/Nout"],
             legend = :left)

    file_str = Serialize.convert(String, options)
    filename = string(
        "data/experiments/deep-kate/iscx/plot_",
        id, "_",
        file_str, "_stats.png")

    display(stats_figure)
    savefig(stats_figure, filename)

end


cic_ids_2017_machine_learning = "data/datasets/iscx/cic-ids-2017/MachineLearningCVE/*.csv"
files = Glob.glob(cic_ids_2017_machine_learning)
@show length(files)
filename = files[1] #1, #6

types = [Float64 for _ in 1:78]
push!(types, String)

open(filename) do file
    global csv = CSV.read(file, delim=',', types = types)
end

M = convert(Matrix, csv[1:78])
L = csv[79]
labels = Dict([l=>id for (id,l) in enumerate(unique(L))])
@show labels
function count_labels(L)
    lcs = Dict{String,Int}() #([l=>id for l in L)])
    for l in L
        if haskey(lcs, l)
            lcs[l] += 1
        else
            lcs[l] = 1
        end
    end
    lcs
end
labels_count = count_labels(L)
@show labels_count
n_outlier = sum([k != "BENIGN" ? v : 0 for (k,v) in labels_count])
@show n_outlier


for _ in 1:1
    seed = Random.rand(1:10000)
    # seed = 8948 #8844 #4634 #1140 #9271 #4507 #3763 #7601 #2539 #2897 #7950 #8844
    id = Dates.format(now(), "yyyy-mm-dd_HHMM")

    train_rel = 0.01
    test_abs  = 50_000

    for latent in [3] #[3, 4]
        for epochs in [0, 1, 10, 30]#,1,10,100] #0, 1, 10] #1, 3]
                iscx(M, L, labels, n_outlier, seed, epochs, latent, id, train_rel, test_abs)
        end
    end
end
