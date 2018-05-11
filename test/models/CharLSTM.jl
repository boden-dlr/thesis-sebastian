using Base.Test
using Flux
using Flux: onehot, argmax, chunk, batchseq, throttle, crossentropy
using StatsBase: wsample
using Base.Iterators: partition
using LogClustering.Sparse
using LogClustering.Sparse: MultiChar
using Flux: relu, leakyrelu, sigmoid
# using CuArrays
using Plots
gr()

# Data & Transformation

file = "/home/sebastian/develop/topic/clustering/LogClustering.jl/data/datasets/RCE/2014-12-02_08-58-09_1048.log"
# file = "/home/sebastian/develop/topic/clustering/LogClustering.jl/data/datasets/RCE/2018-03-01_15-11-18_51750.log"
# file = "/home/sebastian/develop/topic/clustering/LogClustering.jl/data/datasets/test/short.txt"

text = collect(readstring(file))
drop = 32
text_lines = collect(
    map(line -> length(line) > drop ? line[drop:end] : line,
        readlines(file)))

alphabet = [unique(text)..., '¿']
stop = onehot('¿', alphabet)

len_lines = map(l->length(l), text_lines)
len_median = round(Int64, median(len_lines))
len_mean = round(Int64, mean(len_lines))
len_max = round(Int64, maximum(len_lines))
seqlen = round(Int64, len_mean)

# nbatch = round(Int64, length(text_lines) / 100)
# nbatch = round(Int64, 1048 / 3)
# nbatch = 2

# N = length(alphabet)
# text = map(ch -> onehot(ch, alphabet), text)
# Xs = collect(partition(batchseq(chunk(text, nbatch), stop), seqlen))
# Ys = collect(partition(batchseq(chunk(text[2:end], nbatch), stop), seqlen))
# Xs = map(x -> gpu.(x), Xs)
# Ys = map(y -> gpu.(y), Ys)

A = length(alphabet)
N = A * seqlen

text_lines_one_hot = map(
    line -> vcat(map(
        char -> onehot(char, alphabet),
        collect(rpad(line, seqlen, '¿'))[1:seqlen])),
    text_lines)

ls = map(
    line -> reduce((a,b)-> a+length(b), 0, line),
    text_lines_one_hot)
@test all(n -> n == N, ls)

Xs = text_lines_one_hot[1:end-1]
Ys = text_lines_one_hot[2:end]
@show length(Xs), length(Ys)
length(Xs[1])


# Modeling

seed = rand(1:10000)
# seed = 5043
srand(seed)

# L = round(Int64, N/2)
L = 2

m = Chain(
    MultiChar(seqlen, 128, A),
    # MultiChar(seqlen, 128, A, σ=sigmoid),
    # MultiChar(seqlen, 128, A, σ=cos),
    
    # LSTM(128, 64),
    # LSTM(64, L),
    # LSTM(L, 64),
    # LSTM(64, 128),

    LSTM(128, L),
    LSTM(L, 128),

    # Dense(128, 64, leakyrelu),
    # Dense(64, L, sigmoid),
    # Dense(L, 64, leakyrelu),
    # Dense(64, 128, leakyrelu),

    # Dense(128, N, sigmoid),
    Dense(128, N, leakyrelu),
    # Dense(128, N),
    # Dense(128, N),
    softmax) |> gpu

# arch = string(m[1].join, ", ", string(m[2:end]))
arch = string(filter(!isempty, split(string(m[1].join, string(m[2:end])), r"\s+|[\,\(\)\{\}]"))...)

function loss(xs, ys)
    # @show length(xs), length(xs[1])
    # @show length(ys), length(ys[1])
    y_hat = m(xs)
    # @show length(y_hat), length(y_hat[1])
    vys = convert(Array{Float64}, vcat(ys...))
    # @show length(vys), length(vys[1])
    l = sum(crossentropy(y_hat, vys))
    Flux.truncate!(m)
    return l
end

opt = ADAM(params(m), 0.01)
# opt = Flux.ADADelta(params(m))

# evalcb = () -> @show loss(Xs[5], Ys[5])

function sample(m, alphabet, len; temp = 1)
    Flux.reset!(m)
    buf = IOBuffer()
    # noise = rand(alphabet, len) 
    noise = fill(rand(alphabet), len)
    encoded = map(c->onehot(c, alphabet), noise)
    data = m(encoded).data
    a = length(alphabet)
    for i in 1:a:len*a
        c =  wsample(alphabet, data[i:i+a-1])
        write(buf, c)
    end
        
    # map(e -> wsample(alphabet, e), data[1:a])
    # for i = 1:len
    #   write(buf, c)
    # #   c = wsample(alphabet, m(onehot(c, alphabet)).data)
    # end
    # @show String(take!(buf))

    String(take!(buf))
end

evalcb = function ()
    l = loss(Xs[1], Ys[1])
    @show l
    if l.tracker.data <= 1550
        return :stop
    end
    println()
    println(sample(deepcopy(m), alphabet, seqlen))
    println(repeat("-", 72))
end

# Training
Flux.testmode!(m, false)
@time Flux.train!(loss, zip(Xs, Ys), opt, cb = throttle(evalcb, 5))


# # Sampling

# sample(m, alphabet, 1000) |> println


# Saving the model

Flux.testmode!(m)
Flux.reset!(m)

function embed(oh, m)
    Flux.truncate!(m)
    # Flux.reset!(m)
    m[1:3](oh).data
end

offset = 500
from = 1 + offset
step = round(Int64, length(text_lines_one_hot) / 100)
to = length(text_lines_one_hot) - offset

embedded = @time map(
    line -> embed(line, m),
    text_lines_one_hot[from:step:to])

S = length(text_lines)
E = length(embedded)
l = loss(Xs[1], Ys[1])
l_str = @sprintf("%.0f", l)

basestr = "data/embedding/charlstm/CharLSTM_$arch\_$S\N\_$seed\seed\_$L\_$l_str\loss\_$E\E\_$from\_$step\_$to\_"

writedlm(string(basestr, "embedded.csv"), embedded)

results = hcat([e for e in embedded]...)

label=[string("embedded:$E (loss: $l_str)")]
fig = nothing
if L == 2
    fig = scatter(results[1,:], results[2,:], label=label)
elseif L == 3
    fig = scatter3d(results[1,:], results[2,:], results[3,:], label=label)
end
# current()
savefig(fig, string(basestr, "embedded.png"))
