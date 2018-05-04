using Flux
using Flux: onehot, argmax, chunk, batchseq, throttle, crossentropy
using StatsBase: wsample
using Base.Iterators: partition
# using CuArrays

# Data & Transformation

# file = "/home/sebastian/develop/topic/clustering/LogClustering.jl/data/datasets/RCE/2014-12-02_08-58-09_1048.log"
# file = "/home/sebastian/develop/topic/clustering/LogClustering.jl/data/datasets/RCE/2018-03-01_15-11-18_51750.log"
file = "/home/sebastian/develop/topic/clustering/LogClustering.jl/data/datasets/test/short.txt"

text = collect(readstring(file))
text_lines = collect(readlines(file))

alphabet = [unique(text)..., '¿']
stop = onehot('¿', alphabet)

len_median = round(Int64, median(map(l->length(l), text_lines)))
len_mean = round(Int64, mean(map(l->length(l), text_lines)))
len_max = round(Int64, maximum(map(l->length(l), text_lines)))
seqlen = round(Int64, len_mean)
# nbatch = round(Int64, length(text_lines) / 100)
# nbatch = round(Int64, 1048 / 3)
nbatch = 2

N = length(alphabet)
text = map(ch -> onehot(ch, alphabet), text)
Xs = collect(partition(batchseq(chunk(text, nbatch), stop), seqlen))
Ys = collect(partition(batchseq(chunk(text[2:end], nbatch), stop), seqlen))
Xs = map(x -> gpu.(x), Xs)
Ys = map(y -> gpu.(y), Ys)

# A = length(alphabet)
# N = A * seqlen
# text_lines_one_hot = map(
#     line -> map(
#         char -> onehot(char, alphabet),
#         collect(rpad(line, N, '¿'))[1:N]),
#     text_lines)

# Xs = text_lines_one_hot[1:end-1]
# Ys = text_lines_one_hot[2:end]
# @show length(Xs), length(Ys)
# length(Xs[1])


# Modeling

# L = round(Int64, N/2)
L = 3

m = Chain(
  Dense(N, 128),
  LSTM(128, L),
  LSTM(L, 128),
  Dense(128, N),
  softmax) |> gpu

function loss(xs, ys)
  l = sum(crossentropy.(m.(xs), ys))
  Flux.truncate!(m)
  return l
end

opt = ADAM(params(m), 0.01)
# opt = Flux.ADADelta(params(m))

# evalcb = () -> @show loss(Xs[5], Ys[5])

function sample(m, alphabet, len; temp = 1)
    Flux.reset!(m)
    buf = IOBuffer()
    c = rand(alphabet)
    for i = 1:len
      write(buf, c)
      c = wsample(alphabet, m(onehot(c, alphabet)).data)
    end
    return String(take!(buf))
end

evalcb = function ()
    l = loss(Xs[1], Ys[1])
    @show l, typeof(l), eltype(l)
    if l.tracker.data <= 800
        return :stop
    end
    println()
    println(sample(deepcopy(m), alphabet, seqlen))
    println(repeat("-", 72))
end

# Training

time_start = now()
Flux.train!(loss, zip(Xs, Ys), opt,
            cb = throttle(evalcb, 5))
time_end = now()
time_elapsed = time_end - time_start
@show time_elapsed

# Sampling

sample(m, alphabet, 1000) |> println


# Saving the model

Flux.testmode!(m)

function embed(oh, m)
    Flux.reset!(m)
    m[2](oh).data
end

embedded = map(
    line -> map(
        ohot -> embed(ohot, m),
        collect(line)),
    text_lines_one_hot[1:end])

S = length(text_lines)

writedlm("data/embedding/charlstm/CharLSTM_$S\_embedded.csv", embedded, ';')
