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

input = KATE.transform_text_to_input("input.txt", 1000)
# @show typeof(input), typeof(wc)

# Xs, Ys = deepcopy(input), deepcopy(input)
# Xs, Ys = deepcopy([input]), deepcopy([input])
Xs, Ys = [deepcopy(input)], [deepcopy(input)]
@show typeof(Xs), typeof(Ys)
@show length(Xs), length(Ys), length(Xs[1]), length(Ys[1])
# @show Xs, Ys

N = length(input)

m = Chain(
    Dense(N, 128, tanh),
    KCompetetive(128, 128, tanh),
    Dense(128, N, sigmoid),
    softmax)

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

@progress for i = 1:5000
    info("Epoch $i")
    Flux.train!(
        loss,
        zip(Xs, Ys),
        opt,
        cb = evaluation_callback)
end

# function sample(m, alphabet, len; temp = 1)
#     buf = IOBuffer()
#     c = rand(alphabet)
#     for i = 1:len
#         write(buf, c)
#         c = wsample(alphabet, m(onehot(c, alphabet)).data)
#     end
#     return String(take!(buf))
# end
