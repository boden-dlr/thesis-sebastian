using LogClustering.KATE
using LogClustering.KATE: KCompetetive
using Base.Test
using Flux
using Flux: throttle
using Flux: crossentropy #, binarycrossentropy
using Juno: @progress

cd(@__DIR__)

isfile("input.txt") ||
  download("http://cs.stanford.edu/people/karpathy/char-rnn/shakespeare_input.txt",
           "input.txt")

input, wc = KATE.transform_text_to_input("input.txt", 1000)
vocabulary = collect(keys(wc))

# Xs, Ys = deepcopy(input), deepcopy(input)
# Xs, Ys = deepcopy([input]), deepcopy([input])
Xs, Ys = [deepcopy(input)], [deepcopy(input)]
@show typeof(Xs), typeof(Ys)
@show length(Xs), length(Ys), length(Xs[1]), length(Ys[1])
# @show Xs, Ys

N = length(input)

k = 64

m = Chain(
    KCompetetive(N, k, tanh),
    Dense(k, N, sigmoid)
)

function loss(xs, ys)
    # @show typeof(xs), typeof(ys)
    l = crossentropy(m(xs), ys)
    # @show typeof(l), l
    return l
end

function evaluation_callback()
    @show loss(Xs[1], Ys[1])
end

opt = Flux.ADADelta(params(m))

@progress for i = 1:10
    info("Epoch $i")
    Flux.train!(
        loss,
        zip(Xs, Ys),
        opt,
        cb = throttle(evaluation_callback, 30))
end

# @show KATE.get_similar_words(m, 1, vocabulary)
