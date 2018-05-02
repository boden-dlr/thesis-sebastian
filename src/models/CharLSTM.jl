using Flux
using Flux: onehot, argmax, chunk, batchseq, throttle, crossentropy
using StatsBase: wsample
using Base.Iterators: partition
using CuArrays


# Data & Transformation

file = "/home/sebastian/develop/topic/clustering/LogClustering.jl/data/datasets/RCE/2014-12-02_08-58-09_1048.log"

text = collect(readstring(file))
text_lines = readlines(file)

alphabet = [unique(text)..., '¿']
stop = onehot('¿', alphabet)
N = length(alphabet)
seqlen = round(Int64, median(map(l->length(l), text_lines)))
# nbatch = round(Int64, length(text_lines) / 100)
# nbatch = round(Int64, 1048 / 3)
nbatch = 10

text = map(ch -> onehot(ch, alphabet), text)

Xs = collect(partition(batchseq(chunk(text, nbatch), stop), seqlen))
Ys = collect(partition(batchseq(chunk(text[2:end], nbatch), stop), seqlen))
Xs = map(x -> gpu.(x), Xs)
Ys = map(y -> gpu.(y), Ys)


# Modeling

# L = round(Int64, N/2)
L = 16

m = Chain(
  LSTM(N, 128),
  Dense(128, L, tanh),
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
  @show loss(Xs[5], Ys[5])
  println()
  println(sample(deepcopy(m), alphabet, 100))
  println(repeat("-", 72))
end


# Training

Flux.train!(loss, zip(Xs, Ys), opt,
            cb = throttle(evalcb, 10))


# Sampling

sample(m, alphabet, 1000) |> println
