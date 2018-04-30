using Base.Test

using LogClustering.NLP, LogClustering.KATE
using LogClustering.KATE: KCompetetive

using Flux
using Flux: throttle, crossentropy, testmode! #, binarycrossentropy
using Juno: @progress
using Plots
gr()

# using Rsvg
# plotlyjs()

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
const dataset = string(basedir, "/data/datasets/RCE/")

# lines = vcat(map(
#     (log) -> readlines(string(dataset, log)),
#     take(string(dataset), 1)
# )...)
    # readlines(string(base, "/data/logs/", "2014-12-02_10-45-57_922.log")),
    # readlines(string(base, "/data/logs/", "2016-06-08_17-12-52_6852.log")),
# lines = readlines(string(dataset, "2014-12-02_08-58-09_1048.log"))
# lines = readlines(string(dataset, "2018-03-01_12-58-22_32800.log"))
# lines = readlines(string(dataset, "2018-03-01_15-11-18_51750.log"))
# lines = readlines(string(dataset, "2017-11-28_08-08-42_129250.log"))
# lines = readlines(string(dataset, "2017-12-01_09-02-55_9081.log"))
lines = readlines(string(dataset, "2018-03-01_15-07-59_7296.log"))


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

Xs, Ys = deepcopy(input[1:end-1]), deepcopy(input[2:end])
# Xs, Ys = input[1:end-1], input[2:end]
# Xs, Ys = input, input
@show typeof(Xs), typeof(Ys)
@show length(Xs), length(Ys), length(Xs[1]), length(Ys[1])
# @show Xs, Ys
# input[236:255,1]
# input[400:510,1]
# @show input

# make model reproduceable
# seed = 1235
seed = rand(1:10000)

srand(seed)
S = length(input)
V = length(vocabulary)
N = convert(Int64, length(input[1]))
K = 3 #min(64, convert(Int64, round(N/10)))
Epochs = 1
# truncate = false
@show length(lines), S, V, N, K, Epochs, seed

prefix = string(cwd, S, "S_", V, "V_", N, "N_", K, "K_", seed, "seed_", Epochs, "E") #_", truncate, "truncate")

writecsv("$prefix\_tokenized.csv", tokenized)
writecsv("$prefix\_wordcount.csv", wordcount)

m = Chain(
    KCompetetive(N, K, tanh),
    Dense(K, N, sigmoid))

testmode!(m, false)

function loss(xs, ys)
    # @show typeof(xs), typeof(ys)
    l = crossentropy(m(xs), ys)
    # @show typeof(l), l
    # if truncate
    #     # Flux.truncate!(m)
    #     # Flux.reset!(m)
    # end
    return l
end

training = Vector{Float64}()
function evaluation_callback()
    l = loss(Xs[5], Ys[5])
    @show l, typeof(l)
    push!(training, l.tracker.data)
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


testmode!(m)
# initW = (out,in) -> deepcopy(m[1].W.data)
# initb = (out) -> deepcopy(m[1].b.data)
# d = Dense(N,K,tanh,initW=initW,initb=initb)

maxVal = -Inf
maxIdx = 1
minVal = Inf
minIdx = 1

cluster = Matrix{Float64}(S,K)

for s = 1:S
    embedded = m[1](input[s]).data
    if s < 10
        @show embedded
    end
    cluster[s,:] = embedded
    summed = sum(map(e->e^2,embedded))
    # summed = sum(embedded)
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
    
    # savefig(plot(training), "$prefix\_loss.png")

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

    current()
end
