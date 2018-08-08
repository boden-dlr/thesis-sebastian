using LogClustering: NLP
using DataStructures: OrderedDict

mutable struct Label
    label::String
    multi::Char

    Label(label::Union{String,Symbol} = "*",
          multi::Char = '%', 
          single::Char = '*',
          style::Function=uppercase) = begin

        label = string(label)

        if length(label) == 1 && label != string(single)
            throw(ParseError("a single-char label should be '$single'"))
        end
        if contains(label, string(multi))
            throw(ParseError("a multi-char label should not contain the special char '$multi'"))
        end

        if length(label) == 1
            new(string(label), multi)
        else
            new(style(string(multi, label, multi)), multi)
        end
    end
end

function Base.show(io::IO, l::Label)
    print(io, l.label)
end


function parse_event_log(document::Vector{String};
    line_parser::Union{Vector{Tuple{Regex,Label,ParseFunction}},Void} = nothing,
    word_parser::Union{Vector{Tuple{Regex,Label,ParseFunction}},Void} = nothing,
    line_splitter::Regex = r"\s+",
    label_chars::Regex = r"[\*\%]",
    label_char_replacement::Char = '_',
    label_single::Char = '*',
    label_multi::Char = '%',
    join_log_keys::Bool = false) where ParseFunction <: Function

    document = deepcopy(document)

    single = string(label_single)
    multi = string(label_multi)

    log_keys   = Vector{Vector{String}}(length(document))
    log_labels = Vector{Vector{Label}}(length(document))
    log_values = Vector{Vector{Tuple{Any,String}}}(length(document))

    # stage 1 - per line
    if line_parser != nothing && length(line_parser) == 0
        warn("empty line parser")
    else
        for (l,line) in enumerate(document)
            if length(line) == 0
                log_keys[l] = NLP.split_and_keep_splitter(line, line_splitter)
                log_values[l] = Vector{Tuple{Any,String}}()
                log_labels[l] = Vector{Label}()
            else
                line = replace(line, label_chars, label_char_replacement)
                parsed_values = Vector{Pair{Int64,Tuple{Any,String}}}()
                parsed_labels = Vector{Pair{Int64,Label}}()
                for (re, label, pf) in line_parser
                    values = matchall(re, line)
                    for i in eachindex(values)
                        v = values[i]
                        push!(parsed_values, v.offset => (pf(v),v))
                        push!(parsed_labels, v.offset => label)
                    end
                    if label.label == single
                        line = replace(line, re, label.label)
                    else
                        line = replace(line, re, label.label)
                    end
                end

                # subline = SubString(line,1,length(line))
                words = NLP.split_and_keep_splitter(line, line_splitter)
                log_keys[l] = words

                # stage 2 - per word
                if word_parser != nothing && length(word_parser) > 0    
                    ws = Vector{String}()
                    pos = 0
                    for word in words
                        pos += length(word)
                        for (re, label, pf) in word_parser
                            values = matchall(re, word)
                            for i in eachindex(values)
                                v = values[i]
                                push!(parsed_values, pos => (pf(v),v))
                                push!(parsed_labels, pos => label)
                            end
                            if label.label == single
                                word = replace(word, re, label.label)
                            else
                                word = replace(word, re, label.label)
                            end
                        end
                        push!(ws, word)
                    end
                    log_keys[l] = ws #join(ws,"")
                end
                parsed_values = sort(parsed_values, by=kv->kv[1])
                parsed_labels = sort(parsed_labels, by=kv->kv[1])

                log_values[l] = map(kv -> kv[2], parsed_values)
                log_labels[l] = map(kv -> kv[2], parsed_labels)
            end
        end
    end

    log_time = fill(0,length(document))
    last = nothing
    for i in eachindex(log_values)
        if length(log_values[i]) > 0
            value = log_values[i][1][1]
            if value isa Base.Dates.DateTime
                if last == nothing
                    last = value
                end
                log_time[i] = convert(Int64, Dates.value(value - last))
                last = value
            end
        end
    end

    if join_log_keys == true
        for i in eachindex(log_keys)
            log_keys[i] = [join(log_keys[i],"")]
        end
    end

    OrderedDict(
        :log_keys => log_keys,
        :log_labels => log_labels,
        :log_values => log_values,
        :log_time => log_time)
end

function vocabulary(document::NLP.Document, normalize=identity)
    vocab = Dict{String,Int64}()
    for line in document
        for word in line
            word = normalize(word)
            if haskey(vocab, word)
                vocab[word] += 1
            else
                vocab[word] = 1
            end
        end
    end
    NLP.TermCount(sort(collect(vocab), by=kv->kv[2], rev=true))
end


function normalize_by_max(document::NLP.Document, vocab::NLP.TermCount;
    default = 1.0,
    max_length = 1000,
    max_count = -1)

    L = length(document)
    W = min(max_length, maximum(map(length, keys(vocab))))
    if max_count == -1
        max_count = maximum(values(vocab))
    end
    N = fill(default, (L,W))
    for l in 1:L
        for w in 1:W
            if length(document[l]) > w
                word = document[l][w]
                N[l,w] = vocab[word] / max_count
            end
        end
    end
    N
end

function convert_matrix_to_vec_of_vec(M::AbstractMatrix)
    (m,n) = size(M)
    ms = Vector{Vector{eltype(M)}}(m)
    for i in 1:m
        ms[i] = M[i,:]
    end
    ms
end

function parse_rce_datetime(value::AbstractString)
    Dates.DateTime(value, dateformat"yyyy-mm-dd HH:MM:SS,sss")
end

function parse_syslog_datetime(value::AbstractString)
    try
        return Dates.DateTime(value, dateformat"u dd HH:MM:SS")
    catch
        return Dates.DateTime(value, dateformat"u  d HH:MM:SS")
    end
end

function parse_float(value::AbstractString)
    value = replace(value, ",", ".")
    parse(Float64,value)
end

function parse_int(value::AbstractString)
    parse(Int64,value)
end


LineParserExpressions = Dict(
    :rce_datetime => r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}",
    :syslog_datetime => r"[A-Z][a-z]{2}\s{1,2}\d{1,2} \d{2}:\d{2}:\d{2}",
    )

WordParserExpressions = Dict(
    :hex_id => r"^(:?(?=.*[a-fA-F])(?=.*[0-9])([0-9a-fA-F]+)|([0-9a-fA-F]+[\-\_])+[0-9a-fA-F]+)$",
    :float => r"\b\d+[\.\,]\d+\b",
    :int => r"\b\d+\b",
    )

#
# tests
#

include(joinpath(pwd(), "test/models/DeepKATE.jl"))
using PyCall

@pyimport sklearn.cluster as SkCluster
@pyimport sklearn.metrics as SkMetrics
#@pyimport sklearn.preprocessing as SkPreprocess

using Clustering
using LogClustering.Validation: betacv, sdbw
using LogClustering.ClusteringUtils: assignments_to_clustering
using DataFrames
using CSV


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
    # "/home/sebastian/develop/julia/dev/LogClustering.jl/data/datasets/RCE/2017-09-01_13-32-20_21070.log",
]

for filename in filenames
info("file: $filename")

file = readlines(filename)

line_parser = Tuple{Regex,Label,Function}[
    (LineParserExpressions[:rce_datetime], Label(:rce_datetime), parse_rce_datetime),
    # (LineParserExpressions[:syslog_datetime], Label(:syslog_datetime), parse_syslog_datetime),
    # (r"\b\d+[\.\,]\d+\b", Label(:FLOAT), parse_float),
    # (r"\b\d+\b", Label(:INT), parse_int),
    ]

word_parser = Tuple{Regex,Label,Function}[
    (WordParserExpressions[:hex_id], Label(:hex_id), identity),
    (WordParserExpressions[:float], Label(:float), parse_float),
    (WordParserExpressions[:int], Label(:int), parse_int),
    ]

event_log = parse_event_log(file,
    line_parser = line_parser,
    word_parser = word_parser,
    line_splitter = r"\s+|[\(\)\[\]\{\}\=\:\@\$]+|\,\s|\.\s",
    join_log_keys = false)

event_log[:log_keys]
event_log[:log_labels]
event_log[:log_values]
event_log[:log_time]

# using BenchmarkTools

log_keys = [join(lk) for lk in event_log[:log_keys]]

vocab = vocabulary(event_log[:log_keys])
data_matrix = normalize_by_max(event_log[:log_keys], vocab)
data_vec = convert_matrix_to_vec_of_vec(data_matrix)



# TODO: encode vocab to frequencies, to concat them to the frequency normalized log_key and put them into KATE.
# vocab = vocabulary(event_log[:log_values])



for rounds in 1:10
info("round: $rounds")

n_samples = length(log_keys)
seed  = rand(1:10000)


for latent in [2,3,10,100]
info("latent: $latent")

for epochs in [0,1,3]
info("epochs: $epochs")
# epochs = 1

train = rand(1:n_samples, round(Int64, n_samples * 0.7))
test = setdiff([1:n_samples...], train)

model = fit_deep_kate(data_vec[train], seed, latent, epochs)
embeddings, reconstruction = generate(model, data_vec[test])
(reconstruction_errors, std_error, median_error, mean_error) = reconstruction_error(data_matrix[test,:], reconstruction)

# embeddings = SkPreprocess.StandardScaler()[:fit_transform](embeddings)
embeddings = scale(embeddings)

for min_neighbors_dbscan in [2,5,10]
info("neighbors: $min_neighbors_dbscan")
# min_neighbors_dbscan = 10
for epsilon in [0.001, 0.01, 0.03, 0.05, 0.1]
info("epsilon: $epsilon")
# epsilon = 0.03
#algorithm = "auto" # "ball_tree", "kd_tree"
sk_dbscan = SkCluster.DBSCAN(
    eps=epsilon,
    min_samples=min_neighbors_dbscan,
    algorithm = "ball_tree", # create spheres
    n_jobs=-1)

db = sk_dbscan[:fit](embeddings)
prediction = db[:labels_]

n_cluster = length(IntSet(prediction.+2))-1


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

for min_cluster_size in [2,5,10]
info("min_cluster_size: $min_cluster_size")
# min_cluster_size = 2

function sort_by_value(dict, min_cluster_size = 5)
    descending = sort(collect(dict), by=kv->kv[2], rev=true)
    (label,count) = first(descending)
    count >= min_cluster_size ? label : -1
end
mayority_labels = Dict([log_key => sort_by_value(occs, min_cluster_size) for (log_key,occs) in Y])

target = [mayority_labels[lk] for lk in log_keys[test]]



function add_two(assignments)
    map(a->a+2,assignments)
end
target_jl, prediction_jl = add_two(target), add_two(prediction)

(adj_rand_jl, rand_jl, mirkins_jl, huberts_jl) = randindex(target_jl, prediction_jl)

variation_of_info = varinfo(maximum(IntSet(target_jl)), target_jl, maximum(IntSet(prediction_jl)), prediction_jl)


C_prediction_jl = assignments_to_clustering(prediction_jl)

validation = OrderedDict(
    :samples            => n_samples,
    :seed               => seed,
    :latent             => latent,
    :epochs             => epochs,
    :epsilon            => epsilon,
    :min_neighbors      => min_neighbors_dbscan,
    :min_cluster        => min_cluster_size,
    :n_cluster          => n_cluster,
    :n_log_keys         => length(keys(Y)),
    :compression        => 1-(n_cluster/length(keys(Y))),
    #
    :std_error          => std_error,
    :median_error       => median_error,
    :mean_error         => mean_error,

    # internal
    :betacv             => betacv(C_prediction_jl),
    :scattering         => sdbw(transpose(embeddings), C_prediction_jl, dense=false),
        # :sdbw               => sdbw(transpose(embeddings), C_prediction_jl)
    # comparing - similarity
    :silhouette         => SkMetrics.silhouette_score(embeddings, prediction),
    # external
    :variation_of_info  => variation_of_info,
    :mirkins            => mirkins_jl,
    :accuracy           => SkMetrics.accuracy_score(target, prediction),
    :f1_micro           => SkMetrics.f1_score(target_jl, prediction_jl, average="micro"), #"macro", "weighted"
    :f1_macro           => SkMetrics.f1_score(target_jl, prediction_jl, average="macro", labels=unique(target_jl)),
    :f1_weighted        => SkMetrics.f1_score(target_jl, prediction_jl, average="weighted", labels=unique(target_jl)),
    :homogeneity        => SkMetrics.homogeneity_score(target, prediction),
    :completeness       => SkMetrics.completeness_score(target, prediction),
    :v_measure          => SkMetrics.v_measure_score(target, prediction),
    :rand               => rand_jl,
    # :adj_rand           => SkMetrics.adjusted_rand_score(target, prediction),
    :adj_rand           => adj_rand_jl,
    :adj_mutual_info    => SkMetrics.adjusted_mutual_info_score(target, prediction),
    :huberts            => huberts_jl)

# TOOD: log_keys to global key_ids


# df = nothing
# if df == nothing
#     df = DataFrame(validation)
# else
#     push!(df, validation)
# end
# sort!(df, [order(:samples), order(:min_neighbors), order(:min_cluster)])

df = DataFrame(validation)

if first_entry
    CSV.write(joinpath(pwd(),"data/experiments/deep-kate/scores_v5_train=0.7_test=0.3_.csv"), df)
    first_entry = false
else
    CSV.write(joinpath(pwd(),"data/experiments/deep-kate/scores_v5_train=0.7_test=0.3_.csv"), df, append=true)
end

end
end
end
end
end
end
end
