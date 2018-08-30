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
        "KATE_sig_KATE_sin_sig_sig_sig_sig",
        ".png")
    
    if !isfile(filename)
        fig_str = Serialize.convert(String, options, delim=" ")
        title = string(fig_str[1:floor(Int,end/2)], "\n", fig_str[ceil(Int,end/2):end])

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
        for l in map(m->L[m], c)
            c_ls[labels[l]] += 1
        end
        c_label = argmax(c_ls)
        
        for l in map(m->L[m], c)
            if labels[l] == c_label
                TP += 1
            else
                FP += 1
            end
        end
    end
    TP, FP
end


function iscx(M, L, seed, epochs, latent, id)
    Random.seed!(seed)

    labels = Dict([l=>id for (id,l) in enumerate(unique(L))])

    normalize!(M)
    data = [r for r in rows(M)]
    n = size(M)[1]

    @info n, seed, epochs

    train_ids = Random.rand(1:n, floor(Int, 0.001*n)) #0.001*n
    # train_ids = [1:floor(Int,0.7*n)...]

    # test_ids = Random.rand(1:n, 50000)
    # test_ids = setdiff(test_ids, train_ids)
    test_ids = setdiff(1:n, train_ids)[1:min(end,60_000)]
    # test_ids = test_ids[1:floor(Int, end/2)]
    # test_ids = [1:n...]
    @show length(train_ids), length(test_ids)

    train = data[train_ids]
    test = data[test_ids] #[end-19999:end] #
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

    for epsilon in [0.01, 0.05, 0.1, 0.5, 1.0, 1.5]
        # epsilon = 0.1 # radius
        result = dbscan(embedded', epsilon)
        A = ClusteringUtils.clustering_to_assignments(result)
        C = ClusteringUtils.assignments_to_clustering(A)

        TP, FP = purity(C, L, labels)
        @show TP, FP

        options["eps"]  = epsilon
        options["nc"]   = length(C)
        options["TP"]   = TP
        options["FP"]   = FP
        options["FPTP"] = FP/TP
        options["FPN"]  = FP/n_test
        plot_embedded(embedded, A, options, id)
    end
   
end


cic_ids_2017_machine_learning = "data/datasets/iscx/cic-ids-2017/MachineLearningCVE/*.csv"
files = Glob.glob(cic_ids_2017_machine_learning)
filename = files[1]

types = [Float64 for _ in 1:78]
push!(types, String)

open(filename) do file
    global csv = CSV.read(file, delim=',', types = types)
end

M = convert(Matrix, csv[1:78])
L = csv[79]

for _ in 1:1
    seed = Random.rand(1:10000)
    # seed = 8844
    id = Dates.format(now(), "yyyy-mm-dd_HHMM")

    for latent in [3, 4]
        for epochs in [0, 1, 3]
                iscx(M, L, seed, epochs, latent, id)
        end
    end
end
