using Test

using Memoize
using LogClustering.NLP
using LogClustering.NeuralNets.KATE
using LogClustering.NeuralNets.KATE: KCompetetive

using Flux
using Flux: throttle, crossentropy, mse, testmode!, data #, binarycrossentropy
using Flux: relu, leakyrelu
using Juno: @progress
using Plots
gr()
using Clustering
using NearestNeighbors
using LogClustering.Validation
using LogClustering.ClusteringUtils
using Distances
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

@memoize function generate_input()

    # lines = vcat(map(
    #     (log) -> readlines(string(dataset, log)),
    #     take(string(dataset), 10)
    # )...)

        # readlines(string(base, "/data/logs/", "2014-12-02_10-45-57_922.log")),
        # readlines(string(base, "/data/logs/", "2016-06-08_17-12-52_6852.log")),
    # lines = readlines(string(dataset, "2014-12-02_08-58-09_1048.log"))
    # lines = readlines(string(dataset, "2018-03-01_12-58-22_32800.log"))
    # lines = readlines(string(dataset, "2018-03-01_15-11-18_51750.log"))
    # lines = readlines(string(dataset, "2017-11-28_08-08-42_129250.log"))
    # lines = readlines(string(dataset, "2017-12-01_09-02-55_9081.log"))
    # lines = readlines(string(dataset, "2018-03-01_15-07-59_7296.log"))
    lines = readlines(string(dataset, "2017-11-30_15-09-09_6482.log"))

    replacements::Array{Tuple{Regex,String}} = [
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
        splitby = r"\s+|[\.\,](?!\d)|[^\w\p{L}\-\_\,\.]", #\.
        # splitby = r"\s+",
        replacements = replacements)

    vocabulary = collect(keys(wordcount))
    sort(collect(wordcount), by=kv->kv[2], rev=true)
    input = KATE.normalize(tokenized, wordcount)

    lines, tokenized, wordcount, vocabulary, input
end

lines, tokenized, wordcount, vocabulary, input = generate_input()

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
# 1111 (++)
# 1234 (++)
# 1235 (+)
# 9284 (+)
# 6455 (++)
# 9259 (+++)
# 4528 (++++++)
# 2841 (++++)
# 7235 (++++++)
# 8041 (+++)
# 3064 (++++++)
# 9123 (++++++)

seed = rand(1:10000)
# seed = 4528

srand(seed)
S = length(input)
V = length(vocabulary)
N = convert(Int64, length(input[1]))
L = 2
k = 2
Epochs = 3
# truncate = false
@show length(lines), S, V, N, L, k, Epochs, seed

# non-linearity     score   seed    e   splitby sdbw                    betacv
# sin               +++++   
#                           9162    3           1.1638061333968182e-5   0.9889554864660729
#                           9123    3           1.6119848050574754e-6   1.6315651945354714
#                           4528    1           1.7548632879987567e-6   0.9086917275128038
#                           4528    3   ^.      2.0686011117887896e-6   1.089201775494748
#                   !!      2778    3           2.087379617794293e-6    1.5754735035243386
#                           3064    3           2.1552954970180808e-6   1.603549212939039
#                           5161    3           2.175532523174756e-6    1.4546332760461984
#                           4528    1   ^.      2.241781177142106e-6    1.602873918045897
#                           4528    10          2.3295263904754054e-6   1.5994303479205059
#                           7645    3           2.3358338559048597e-6   1.1714352363776812
#                   !!!     4528    3           2.7406538233480892e-6   0.5551425843144978
#                           7235    3           3.3473973753875983e-6   1.5851921821411339
#                           8812    3           4.045143746657401e-6    1.54349983115589
# cos               ++++
#                   !!!     2778    3           1.4398618958655482e-6   1.2763952813560353
#                           4528    3           1.8732760463020092e-6   1.722556712467014
#                           9123    3           1.445821165258182e-5    1.9977076333024475
# 
# x->tanh(cos(x))   ++++            3           4.29940081e-6           1.78174876
# sigmoid           ++++
#                           9123    3           0.0001575935929395368   2.0000000004301786
# !1/x              ++++
# !tan              ++++
# x->cos(1/x)       +++             
#                           rand    3           0.00010646              1.99900000
#                           rand    3           0.00015790              2.00000000
# x->cos(exp(x))    ++              
#                           rand    3           0.00019473              2.000000000582213
#                           rand    3           0.00020448333496257166  1.9998402735736103
# !exp              +++
# tanh              +++                                     
#                           9123    3           0.00015530604611594992  2.0000000003673146
# relu              +++
#                           9123    3           0.0001595550566882188   1.99999999981638
# leakyrelu         ++
#                           9123    3           0.00016409326206520976  2.000000000323477
# linear            +
activate = sin

nf = 1
embedded_layer = 3

m = Chain(
    KCompetetive(N, 100, tanh, k=25), # 50 ++++, 25++++, 10 +++++, 5 ++++, 2 +++
    # KCompetetive(100, 5, tanh, k=k),
    # Dense(N, 100*nf, activate),
    # Dropout(0.033),
    Dense(100*nf, 5*nf, activate),

    # Dense(5*nf, 10*nf, activate),
    # Dense(10*nf, 5*nf, activate),
    # Dropout(0.1),
    KCompetetive(5*nf, L, tanh, k=k),
    # Dense(5*nf, L, activate),
    # KCompetetive(L, 50, tanh, k=k),
    # KCompetetive(50, 100, tanh, k=k),
    Dense(L, 5*nf, activate),
    Dense(5*nf, 100*nf, activate),
    # Dense(10*nf, 5*nf, activate),
    # Dense(5*nf, 10*nf, activate),
    Dense(100*nf, N, sigmoid))


# function take2or1(s)
#     f = string(Iterators.take(s, 4)...)
#     l = reverse(string(Iterators.take(reverse(s), 4)...))
#     if f == l
#         return string(f)
#     else
#         return string(f,l)
#     end
# end

arch = string(filter(!isempty, split(string(m), r"\s+|[\,\(\)\{\}]"))...)[1:min(end,120)]

prefix = string(cwd, S, "S_", V, "V_", N, "N_", L, "L_", k, "k_", seed, "seed_", Epochs, "E", arch, "arch_") #_", truncate, "truncate")

writecsv("$prefix\_input.csv", input)
writecsv("$prefix\_tokenized.csv", tokenized)
writecsv("$prefix\_wordcount.csv", wordcount)


# testmode!(m, false)
assert(m[embedded_layer].active == true)

global counter = 0
global bcv = param(0.0)

function bcv_grad(m, Xs)
    m, Xs = deepcopy(m), deepcopy(Xs)
    # Flux.reset!(m)
    embedded_p = map(x->m[1:embedded_layer](x), Xs)
    es_grad = map(es->map(e->e.tracker.grad,es),embedded_p[1:3])
    @show es_grad
    # @show typeof(embedded_p), embedded_p[1:3]
    embedded = map(ta->ta.data, embedded_p)
    embedded = hcat(embedded...)
    # @show typeof(embedded)
    @show embedded[:,1:3]
    C, U = knn_clustering(embedded[:,rand(1:S-1,75)], k=25, metric = Minkowski(2.0))
    # @show typeof(C)
    @show length(C), length(C[1])
    @show mean(map(length, values(C)))
    @show median(map(length, values(C)))
    # @show U
    @show typeof(U), length(U), length(U)/length(Xs)

    Vps = map(c->map(i->embedded_p[i],c),C)
    # @show typeof(Vps)
    @show length(Vps), length(Vps[1]), length(Vps[end])
    bcv = betacv(Vps)
    # es_grad = map(es->map(e->e.tracker.grad,es),embedded_p[1:3])
    # @show es_grad
    # # @show bcv
    # # Flux.back!(bcv)

    # Vs = map(c->map(i->embedded[:,i],c),C)
    # # @show typeof(Vs), length(Vs), length(Vs[1])
    # bcv = betacv(Vs)
    # # @show bcv

    Flux.truncate!(m)
    # # Flux.reset!(m)
    bcv
end

function loss(xs, ys)
    global bcv
    global counter

    l = crossentropy(m(xs), ys)

    # counter += 1
    # # if counter == 10
    # # if counter >= length(Xs)
    # if counter == round(Int64, 0.5*(S-1))
    #     counter = 0 # reset
    #     bcv = bcv_grad(m, Xs)

    #     println("l:     ", l)
    #     println("bcv:   ", bcv)
    #     println("l+bcv: ", l+bcv)
    # end
    
    Flux.truncate!(m)
    # Flux.reset!(m)
    
    return l + bcv
end

training = Vector{Float64}()
function evaluation_callback()
    l = loss(Xs[5], Ys[5])
    println("loss:  ", l)
    push!(training, l.tracker.data)
end

# opt = Flux.ADADelta(params(m))
opt = Flux.ADAM(params(m))

@progress for e = 1:Epochs
    info("Epoch $e")
    Flux.train!(
        loss,
        zip(Xs, Ys),
        opt,
        cb = throttle(evaluation_callback, 30))
end


# 
# Testing
# 

testmode!(m)
m[embedded_layer].active = false
assert(m[embedded_layer].active == false)
# initW = (out,in) -> deepcopy(m[1].W.data)
# initb = (out) -> deepcopy(m[1].b.data)
# d = Dense(N,L,tanh,initW=initW,initb=initb)

maxVal = -Inf
maxIdx = 1
minVal = Inf
minIdx = 1

cluster = zeros(Float64, S,L)

for s = 1:S
    # embedded = m[1](input[s]).data
    embedded = m[1:embedded_layer](input[s]).data
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

C, U = knn_clustering(cluster', k=25, metric = Minkowski(2.0))
Vs = map(c->map(i->cluster'[:,i],c),C)
println("bcv (old): ", bcv)
println("bcv (knn): ", betacv(Vs))
println("sdbw (knn):", sdbw(cluster', C, dense=false))

C_dbscan = dbscan(cluster', 10e-3)
CA_dbscan = clustering_to_assignments(C_dbscan)
C2_dbscan = assignments_to_clustering(CA_dbscan)
DC_dbscan = map(i->cluster'[:,i], CA_dbscan)
println("bcv (dbscan): ", betacv(DC_dbscan))
println("sdbw (dbscan):", sdbw(cluster', C2_dbscan, dense=false))

# p1 = plot(training, label=["loss"])
# savefig(p1,"loss_$Epochs.png")

plot_results = true

if plot_results
    
    # savefig(plot(training), "$prefix\_loss.png")

    if L == 2
        d2 = scatter(cluster[:,1],cluster[:,2], label=["embedded"])
        savefig(d2, "$prefix\_embedded_2d.png")
    end

    if L == 3
        d3 = scatter3d(cluster[:,1],cluster[:,2],cluster[:,3], label=["embedded"])
        savefig(d3, "$prefix\_embedded_3d.png")
    end

    if L == 4
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

prefix
