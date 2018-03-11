using Base.Test

using LogClustering.NLP, LogClustering.KATE
using LogClustering.KATE: KCompetetive

using Flux
using Flux: throttle, crossentropy #, binarycrossentropy
using Juno: @progress
using Plots
# gr()
using Rsvg
plotlyjs()

function take(path::String, n::Int64 = 1)
    all_logs = Vector{String}()
    for (path, _, filenames) in walkdir(path)
        for file in filenames
            if endswith(file, ".log")
                push!(all_logs, file)
            end
        end
    end

    all_logs[1:n]
end

const basedir = pwd()
const cwd = string(basedir, "/data/kate/")

# lines = vcat(map(
#     (log) -> readlines(string(basedir, "/data/logs/", log)),
#     take(string(basedir, "/data/logs/"), 1)
# )...)
    # readlines(string(base, "/data/logs/", "2014-12-02_10-45-57_922.log")),
    # readlines(string(base, "/data/logs/", "2016-06-08_17-12-52_6852.log")),
lines = readlines(string(basedir, "/data/logs/", "2018-03-01_15-11-18_51750.log"))
    # readlines("/home/sebastian/data/log/brigitte_2018-01-25_small.log"),
    # readlines("/home/sebastian/data/log/brigitte_2018-02-01_big.log"),
    # readlines("/home/sebastian/data/log/syslog"),
    # readlines("/home/sebastian/data/log/syslog.2018-02-23_17:07.log"),

replacements = [
    # RCE datetime format
    (r"^\d{4,4}\-\d{2,2}\-\d{2,2}\ \d{2,2}\:\d{2,2}\:\d{2,2}\,\d{3,3}","timestamp"),
    # syslog datetime format
    # (r"\w{3,3}\ \d{2,2}\ \d{2,2}\:\d{2,2}\:\d{2,2}","%timestamp%"),
    # (r"\d{2,2}\:\d{2,2}\:\d{2,2}","%time%"),
    # (r"\d+","%number%"),
]

tokenized, wordcount = NLP.tokenize(
    lines,
    # splitby = r"[^\wäÄöÖüÜ&\.\:\,\;\\\/\-\_\'\%]+",
    #  [\=\(\)\{\}\[\]\\\/\:\;\'\`\"]|
    splitby = r"\s+|[\.\,](?!\d)|[^\w\p{L}\-\_\.\,]",
    replacements = replacements)

vocabulary = collect(keys(wordcount))
sort(collect(wordcount), by=kv->kv[2], rev=true)
input = KATE.normalize(tokenized, wordcount)

Xs, Ys = input[1:end-1], input[2:end]
# Xs, Ys = input, input
@show typeof(Xs), typeof(Ys)
@show length(Xs), length(Ys), length(Xs[1]), length(Ys[1])
# @show Xs, Ys

# make model reproduceable
seed = 1234
srand(seed)
S = length(input)
V = length(vocabulary)
N = convert(Int64, length(input[1]))
K = 3 #min(64, convert(Int64, round(N/10)))
Epochs = 15
@show length(lines), S, V, N, K, Epochs, seed

prefix = string(cwd, S, "S_", V, "V_", N, "N_", K, "K_", Epochs, "E_", seed, "seed")

writecsv("$prefix\_tokenized.csv", tokenized)
writecsv("$prefix\_wordcount.csv", wordcount)

m = Chain(
    KCompetetive(N, K, tanh),
    Dense(K, N, sigmoid))

function loss(xs, ys)
    # @show typeof(xs), typeof(ys)
    l = crossentropy(m(xs), ys)
    # @show typeof(l), l
    # Flux.truncate!(m)
    Flux.reset!(m)
    return l
end

training = Vector{Float64}()
function evaluation_callback()
    l = loss(Xs[5], Ys[5])
    @show l
    push!(training, getindex(l.data))
end

opt = Flux.ADADelta(params(m))

@progress for e = 1:Epochs
    info("Epoch $e")
    Flux.train!(
        loss,
        zip(Xs, Ys),
        opt,
        cb = throttle(evaluation_callback, 30))
end


# initW = (out,in) -> deepcopy(m[1].W.data)
# initb = (out) -> deepcopy(m[1].b.data)
# d = Dense(N,K,tanh,initW=initW,initb=initb)

maxVal = -Inf
maxIdx = 1
minVal = Inf
minIdx = 1

cluster = Matrix{Float64}(S,K)

for s = 1:S
    encoded = m[1](input[s]).data
    if s < 10
        @show encoded
    end
    cluster[s,:] = encoded
    summed = sum(map(e->e^2,encoded))
    # summed = sum(encoded)
    if summed > maxVal
        maxVal = summed
        maxIdx = s
    end
    if summed < minVal
        minVal = summed
        minIdx = s
    end
end

writecsv("$prefix\_embedded_KATE.csv", cluster)

@show cluster[maxIdx,:]
@show cluster[minIdx,:]

@show tokenized[maxIdx]
@show tokenized[minIdx]

# p1 = plot(training, label=["loss"])
# savefig(p1,"loss_$Epochs.png")

plot_results = true

if plot_results

    savefig(plot(training), "$prefix\_loss.png")

    if K == 2
        d2 = scatter(cluster[:,1],cluster[:,2], label=["embedded"])
        savefig(d2, "$prefix\_embedded_2d.png")
    end

    if K == 3
        d3 = scatter3d(cluster[:,1],cluster[:,2],cluster[:,3], label=["embedded"])
        savefig(d3, "$prefix\_embedded_3d.png")
    end

    if K == 4
        d4 = plot(
            scatter3d(cluster[:,1],cluster[:,2],cluster[:,3], label=["1,2,3"]),
            scatter3d(cluster[:,1],cluster[:,2],cluster[:,4], label=["1,2,4"]),
            scatter3d(cluster[:,1],cluster[:,3],cluster[:,4], label=["1,3,4"]),
            scatter3d(cluster[:,2],cluster[:,3],cluster[:,4], label=["2,3,4"]),
            label=["embedded","embedded","embedded","embedded "],
        )
        savefig(d4, "$prefix\_embedded_4d.png")
    end

    # current()
end
