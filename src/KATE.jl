module KATE

using Flux
using Flux: onehot, argmax, chunk, batchseq, throttle, crossentropy, sigmoid, treelike, glorot_uniform
using Flux.Tracker: data
using StatsBase: wsample
using Base.Iterators: partition
using DataStructures

mutable struct KCompetetive{F,S,T}
  σ::F          # activation function
  W::S          # weights
  b::T          # bias
  k::Int64      # k competition
  α::Float64    # boost
  active::Bool  # training vs. test mode
end

KCompetetive(W, b) = KCompetetive(W, b, tanh)

function KCompetetive(
    in::Integer, out::Integer, σ = tanh;
    initW = glorot_uniform, initb = zeros,
    k::Int64 = round(Int64, out/2),
    α::Float64 = 6.26,
    active = true)
  if k > out
    warn("k should not be larger than dim (out): $out, found (k): $k, using: $out")
    k = out
  end
  return KCompetetive(σ, param(initW(out, in)), param(initb(out)), k, α, active)
end

Flux.@treelike(KCompetetive)

function (a::KCompetetive)(x)
    σ, W, b, k, α = a.σ, a.W, a.b, a.k, a.α

    z = σ.(W*x .+ b)

    # Only apply K-Competetion in the training phase.
    a.active || return z

    ps = Vector{Tuple{Int64,Float64}}()
    ns = Vector{Tuple{Int64,Float64}}()

    for (i, activation) = enumerate(data(z))
        if activation >= 0
            push!(ps, (i, activation))
        else
            push!(ns, (i, activation))
        end
    end
    ps = sort(ps, by=last) # ascending
    ns = sort(ns, by=last, rev=true)  # descending
    P = length(ps)
    N = length(ns)

    z_hat = data(z)
    
    p = P-round(Int64, k/2, RoundUp)
    if p > 0
        Epos = sum(map(last, ps[1:p]))
        for i = p+1:P
            # positive winners
            z_hat[first(ps[i])] = z_hat[first(ps[i])] + (α * Epos)
        end
        for i = 1:p
            # positive losers
            z_hat[first(ps[i])] = 0.0
        end
    end

    n = N-round(Int64, k/2, RoundDown)
    if n > 0
        Eneg = sum(map(last, ns[1:n]))
        for i = n+1:N
            # negative winners
            z_hat[first(ns[i])] = z_hat[first(ns[i])] + (α * Eneg)
        end
        for i = 1:n
            # negative losers
            z_hat[first(ns[i])] = 0.0
        end
    end

    # Return z instead of z_hat in order to conserve 
    # the gradient for back-propagation. This is possible
    # as z_hat is only a reference to z.
    return z 
end


Flux._testmode!(a::KCompetetive, test) = (a.active = !test)


function Base.show(io::IO, l::KCompetetive)
  print(io, "KCompetetive(", size(l.W, 2), ", ", size(l.W, 1))
  l.σ == identity || print(io, ", ", l.σ)
  print(io, ", ", l.k)
  print(io, ", ", l.α)
  print(io, ", ", l.active)
  print(io, ")")
end


function log_by_frequency(word::String, wc::DataStructures.OrderedDict{String,Int64}, V::Int)
    n = wc[word]
    logwc = log(1+n)
    logwc/V*logwc
end

# ::Array{String}
function normalize(tokens::Array{Array{String,1},1},
    word_count::DataStructures.OrderedDict{String,Int64},
    padding::Float64=1.0)
    V = length(word_count)
    numeric = map(
        line -> map(
            word -> log_by_frequency(word, word_count, V), line),
        tokens)
    N = maximum(map(line -> length(line), numeric))
    padded = map(line -> rpad(line, N, padding), numeric)
    padded
end

# TODO: implement
function get_similar_words(model, query_id, vocab; topn=10)
    # @show vocab
    W = model[1].W.data
    W = W/norm(W)
    query = W[query_id]
    # @show query
    score = query*(transpose(W))
    # @show score
    # @show size(score), typeof(score)
    # @show score[:,1]
    # @show size(score[:,1]), typeof(score[:,1])
    vidx = sort(score[:,1])[1:topn]
    # @show vidx
    # weights = unitmatrix(weights) # normalize
    # query = weights[query_id]
    # score = query.dot(weights.T)
    # vidx = score.argsort()[::-1][:topn]

    return [vocab[idx] for idx in vidx]
end

end # module KATE
