module Sparse

using Flux
using Flux: treelike

mutable struct MultiChar{A,L}
    in::A
    out::A
    # n::A
    a::A
    m::A
    layers::Array{L}
    join::L
    # σ::F
    active::Bool
end

function MultiChar(
    in::Integer,
    out::Integer,
    a::Integer;
    L = Dense,
    σ::Function = tanh,
    m::Integer = 1,
    active::Bool = true)

    layers = map(i-> L(a, m, σ), 1:in)
    join = L(in * m, out, σ)

    @show typeof(L)
    # MultiChar(in, out, n, a, m, layers, join, σ, active)
    MultiChar(in, out, a, m, layers, join, active)
end

function (m::MultiChar)(xs)
    layers, join = m.layers, m.join
    js = vcat(map(x_i -> layers[x_i[1]](x_i[2]), enumerate(xs))...)
    # @show js
    join(js)
end

treelike(MultiChar)


# m = MultiChar(11, 5, 20)

# xs = map(i -> rand(0:1, 20), 1:11)

# ys=[-0.0546049,
# 0.0180089,
# 0.0219684,
# 0.0168478,
# -0.00567532]

# using Flux: crossentropy, mse

# function loss(xs, ys)
#     y_hat = m(xs)
#     @show y_hat, ys
#     mse(y_hat, ys)
#     # m.truncate!()
# end

# l = loss(xs, ys)

# Flux.back!(l)

# m.layers[1].cell.Wi.grad
# m.layers[1].cell.Wh.grad

# m.join.cell.Wi.grad
# m.join.cell.Wh.grad

end