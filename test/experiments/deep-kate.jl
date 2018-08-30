using LogClustering.NLP
using LogClustering.Parsing
using LogClustering.Parsing: Label, Parser, Splitter
# using LogClustering.Models
using LogClustering.Sequence
using LogClustering.Validation: betacv, sdbw, arsd
using LogClustering.ClusteringUtils: assignments_to_clustering
using LogClustering.RegExp
# using LogClustering.KATE

using Dates
using Plots
gr()
#plotlyjs()
using DataStructures
using Statistics
using Random
using Clustering
using DataFrames
using CSV
using PyCall
@pyimport sklearn.cluster as SkCluster
@pyimport sklearn.metrics as SkMetrics
#@pyimport sklearn.preprocessing as SkPreprocess

include(joinpath(pwd(), "test/models/DeepKATE.jl"))

first_entry = true

# file = readlines("/home/sebastian/develop/julia/dev/LogClustering.jl/data/datasets/test/syslog")
# file = readlines("/home/sebastian/develop/julia/dev/LogClustering.jl/data/datasets/RCE/2017-02-21_16-11-52_77886.log")
# file = readlines("/home/sebastian/develop/julia/dev/LogClustering.jl/data/datasets/RCE/2016-12-14_09-00-53_243818.log")
# file = readlines("/home/sebastian/develop/julia/dev/LogClustering.jl/data/datasets/RCE/2017-11-28_08-08-42_129250.log")
# file = readlines("/home/sebastian/develop/julia/dev/LogClustering.jl/data/datasets/RCE/2018-03-01_15-11-18_51750.log")

filenames = [
    joinpath(pwd(),"data/datasets/RCE/2014-12-02_08-58-09_1048.log"),
    joinpath(pwd(),"data/datasets/RCE/2017-10-04_19-30-58_1357.log"),
    joinpath(pwd(),"data/datasets/RCE/2017-02-24_10-25-48_2407.log"),
    joinpath(pwd(),"data/datasets/RCE/2016-09-26_16-15-03_5495.log"),
    joinpath(pwd(),"data/datasets/RCE/2017-02-24_10-26-01_6073.log"),
    joinpath(pwd(),"data/datasets/RCE/2017-11-30_15-09-09_6482.log"),
    joinpath(pwd(),"data/datasets/RCE/2018-03-01_15-11-18_51750.log")
]

# rounds_options      = 1:10
# latents_options     = [2,3,10,100]
# epochs_options      = [0,1,3]
# neighbors_options   = [2,5,10]
# epsilon_options     = [0.001, 0.01, 0.03, 0.05, 0.1]
# min_cluster_options = [2,5,10]

# filenames           = [filenames[1]]
unique_id           = Dates.format(now(), "yyyy-mm-dd_HHMM")
verbose             = false
anomaly_detection   = false
rounds_options      = 1:1
latents_options     = [2, 3, 4]
epochs_options      = [0, 1, 3]
neighbors_options   = [1]
epsilon_options     = [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0, 1.5, 2.0]
min_cluster_options = [2]

function add_two(assignments)
    map(a->a+2,assignments)
end

figure_index = 0

for filename in filenames
@info "file: $filename"

# filename = filenames[1]
# file = vcat([readlines(filename) for filename in filenames]...)
file = readlines(filename)

log_labels = Tuple{Label,Regex,Function}[
    Parser[:rce_datetime],
    # Parser[:syslog_datetime],
    Parser[:ipv4],
    Parser[:float],
    Parser[:file],
    Parser[:path],
    # Parser[:uri],
    Parser[:hex_id],
    Parser[:id],
    Parser[:int],
    ]

event_log = Parsing.parse_event_log(file, log_labels, Splitter[:positive])

n = length(event_log.log_keys)
event_log.log_values
event_log.log_times

# using BenchmarkTools

log_keys = [join(lk) for lk in event_log.log_keys]

# data_matrix = hcat(KATE.normalize(event_log.log_keys, NLP.count_terms(event_log.log_keys))...)'

data_matrix = Parsing.normalize_log_keys(event_log, padding = 200)
values_matrix = Parsing.normalize_log_values(event_log, padding = 250)

# for anomaly detection, include data...
if anomaly_detection
    @info "anomaly detection: active"
    data_matrix = hcat(data_matrix, values_matrix)
end

# @show size(data_matrix)
# data_matrix = hcat(data_matrix, values_matrix)
# @show size(data_matrix)

data_vec = collect(Sequence.rows(data_matrix))


for rounds in rounds_options
@info "round: $rounds"
n_samples = length(log_keys)
seed = rand(1:10000)
# seed = 1111

for latent in latents_options
@info "latent: $latent"

for epochs in epochs_options
@info "epochs: $epochs seed: $seed"
# epochs = 1

# train = rand(1:n_samples, round(Int64, n_samples * 0.7))
# test = setdiff([1:n_samples...], train)

# train = [1:n_samples...]
train = Random.rand(1:n_samples, floor(Int64, 0.1 * n_samples))
test = [1:n_samples...]

model = fit_deep_kate(data_vec[train], seed, latent, epochs)
embeddings, reconstruction = generate(model, data_vec[test])
(reconstruction_errors, std_error, median_error, mean_error) = reconstruction_error(data_matrix[test,:], reconstruction)

# embeddings = SkPreprocess.StandardScaler()[:fit_transform](embeddings)
embeddings = scale(embeddings)

for min_neighbors_dbscan in neighbors_options
@info "neighbors: $min_neighbors_dbscan"
# min_neighbors_dbscan = 10
for epsilon in epsilon_options
@info "epsilon: $epsilon"
# epsilon = 0.03
#algorithm = "auto" # "ball_tree", "kd_tree"
sk_dbscan = SkCluster.DBSCAN(
    eps=epsilon,
    min_samples=min_neighbors_dbscan,
    algorithm = "ball_tree", # create spheres
    n_jobs=-1)

db = sk_dbscan[:fit](embeddings)
prediction = convert.(Int64,db[:labels_])
prediction_jl = add_two(prediction)

n_cluster = length(BitSet(prediction.+2))-1

Y = Dict{String,Dict{Int64,Int64}}()
for (l, label) in enumerate(prediction)
    log_key = log_keys[test[l]]
    if haskey(Y, log_key)
        if haskey(Y[log_key], label)
            Y[log_key][label] += 1
        else
            Y[log_key][label] = 1
        end
    else
        Y[log_key] = Dict(label => 1)
    end
end

for min_cluster_size in min_cluster_options
@info "min_cluster_size: $min_cluster_size"
# min_cluster_size = 2

function sort_by_value(dict, min_cluster_size = 5)
    descending = sort(collect(dict), by=kv->kv[2], rev=true)
    (label,count) = first(descending)
    count >= min_cluster_size ? label : -1 # TODO: activate again
    # count >= min_cluster_size ? label : descending[min(2,end)][1]
end
mayority_labels = Dict([log_key => sort_by_value(occs, min_cluster_size) for (log_key,occs) in Y])
target = [mayority_labels[lk] for lk in log_keys[test]]
target_jl = add_two(target)


(adj_rand_jl, rand_jl, mirkins_jl, huberts_jl) = Clustering.randindex(target_jl, prediction_jl)

variation_of_info = Clustering.varinfo(
    maximum(BitSet(target_jl)),
    target_jl,
    maximum(BitSet(prediction_jl)),
    prediction_jl)

C_prediction_jl = assignments_to_clustering(prediction_jl)
# @show C_prediction_jl
# @show size(embeddings)

s_dbw_res, scattering, dense_bw = sdbw(transpose(embeddings), C_prediction_jl, dense=false)


validation = OrderedDict(
    :samples            => n_samples,
    :train              => length(train),
    :test               => length(test),
    :seed               => seed,
    :latent             => latent,
    :epochs             => epochs,
    :epsilon            => epsilon,
    :min_neighbors      => min_neighbors_dbscan,
    :min_cluster        => min_cluster_size,
    :n_cluster          => n_cluster,
    :n_log_keys         => length(keys(Y)),
    :compression        => 1-(n_cluster/length(keys(Y))),
    :std_error          => std_error,
    :median_error       => median_error,
    :mean_error         => mean_error,

    # data measure
    :l_var              => Statistics.var(embeddings),
    :l_std              => Statistics.std(embeddings),
    :l_median           => Statistics.median(embeddings),
    :l_mean             => Statistics.mean(embeddings),

    # internal-indices
    :betacv             => betacv(embeddings, C_prediction_jl),
    :scattering         => scattering,
    # :sdbw               => s_dbw_res,
    :arsd               => arsd(embeddings, C_prediction_jl),

    # relative-indices
    :silhouette         => try SkMetrics.silhouette_score(embeddings, prediction) catch nothing end, # does not like big files...

    # external-indices
    :variation_of_info  => variation_of_info,
    :mirkins            => mirkins_jl,
    :accuracy           => SkMetrics.accuracy_score(target, prediction),
    :f1_micro           => SkMetrics.f1_score(target_jl, prediction_jl, average="micro"), #"macro", "weighted"
    :f1_macro           => SkMetrics.f1_score(target_jl, prediction_jl, average="macro", labels=unique(target_jl)), # target_jl
    :f1_weighted        => SkMetrics.f1_score(target_jl, prediction_jl, average="weighted", labels=unique(target_jl)),
    :homogeneity        => SkMetrics.homogeneity_score(target, prediction),
    :completeness       => SkMetrics.completeness_score(target, prediction),
    :v_measure          => SkMetrics.v_measure_score(target, prediction),
    :rand               => rand_jl,
    # :adj_rand           => SkMetrics.adjusted_rand_score(target, prediction),
    :adj_rand           => adj_rand_jl,
    :adj_mutual_info    => SkMetrics.adjusted_mutual_info_score(target, prediction),
    :huberts            => huberts_jl)


# df = nothing
# if df == nothing
#     df = DataFrame(validation)
# else
#     push!(df, validation)
# end
# sort!(df, [order(:samples), order(:min_neighbors), order(:min_cluster)])

df = DataFrame(validation)

# name = "data/experiments/deep-kate/scores_v6_train=0.7_test=0.3_algo=ball_tree.csv"


name = string("data/experiments/deep-kate/test_all_", unique_id, ".csv")
if first_entry
    CSV.write(joinpath(pwd(),name), df)
    first_entry = false
else
    CSV.write(joinpath(pwd(),name), df, append=true)
end


if verbose
    reps = collect(keys(Dict{String,Union{Regex,Nothing}}(
        Parser[:rce_datetime][1].label => Parser[:rce_datetime][2],
        Parser[:hex_id][1].label => nothing,
        Parser[:file][1].label => nothing,
        Parser[:path][1].label => nothing,
        Parser[:ipv4][1].label => nothing,
        Parser[:uri][1].label => nothing,
        Parser[:id][1].label => nothing,
        Parser[:float][1].label => r"\d+[,.]\d+",
        Parser[:int][1].label => r"\d+",
        )))

    for (i, C_i) in enumerate(C_prediction_jl)
        members = C_i
        if length(C_i) > 1
            lks = event_log.log_keys[members][1:min(end,20)]
            re = RegExp.infer(lks, replacements = reps, regex=true)
            @info string(i, "\t", length(C_i))
            # for l in eachindex(lks)
            #     if l % 2 == 0
            #         @info "   ", lks[l]
            #     else
            #         warn(lks[l])
            #     end
            # end
            println("\t", re)
            println()
        end
    end
end

# @show event_log.log_keys

figure_index += 1

if latent == 2
    figure_raw = scatter(embeddings[:,1], embeddings[:,2],
    marker_z = prediction_jl,
    labels = ["embedded"],
    title = "n: $n, seed: $seed, latent: $latent, epoch: $epochs, eps: $epsilon")
else #if latent == 3
    figure_raw = scatter3d(embeddings[:,1], embeddings[:,2], embeddings[:,3],
    marker_z = prediction_jl,
    labels = ["embedded"],
    title = "n: $n, seed: $seed, latent: $latent, epoch: $epochs, eps: $epsilon")
end

savefig(figure_raw,string(
    "data/experiments/deep-kate/plots/latent_",
    unique_id, "_",
    figure_index, ".png"))

display(figure_raw)

@show df
# @show minimum(embeddings)
# @show maximum(embeddings)

# sleep(10)

end
end
end
end
end
end
end
