using Flux
using Flux: onehot, argmax, chunk, batchseq, throttle, crossentropy
using StatsBase: wsample
using Base.Iterators: partition

cd(@__DIR__)

isfile("input.txt") ||
  download("http://cs.stanford.edu/people/karpathy/char-rnn/shakespeare_input.txt",
           "input.txt")

text = collect(readstring("input.txt"))
alphabet = [unique(text)..., '¿']
text = map(ch -> onehot(ch, alphabet), text)
stop = onehot('¿', alphabet)

N = length(alphabet)
seqlen = 25
nbatch = 50

Xs = collect(partition(batchseq(chunk(text, nbatch), stop), seqlen))
Ys = collect(partition(batchseq(chunk(text[2:end], nbatch), stop), seqlen))

m = Chain(
  LSTM(N, 2),
  LSTM(2, 128),
  Dense(128, N),
  softmax)

function loss(xs, ys)
  l = sum(crossentropy.(m.(xs), ys))
  Flux.truncate!(m)
  # Flux.reset!(m)
  return l
end

# opt = ADAM(params(m), 0.01)
opt = Flux.ADADelta(params(m))

function evalcb()
    @show loss(Xs[5], Ys[5])
    # fixed = m[1:1].(Xs[5])
    # @show size(fixed), size(fixed[1]), typeof(fixed)
    # @show fixed[1]
end

Flux.train!(loss, zip(Xs, Ys), opt,
            cb = throttle(evalcb, 30))

# Sampling

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

sample(m, alphabet, 1000) |> println

# evalcb = function ()
#   @show loss(Xs[5], Ys[5])
#   println(sample(deepcopy(m), alphabet, 100))
# end
