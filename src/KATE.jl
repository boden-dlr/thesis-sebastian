module KATE

using Flux
using Flux: onehot, argmax, chunk, batchseq, throttle, crossentropy, sigmoid, treelike, glorot_uniform
using Flux.Tracker: data
using StatsBase: wsample
using Base.Iterators: partition

struct KCompetetive{F,S,T}
  σ::F
  W::S
  b::T
  α::Float64 # boost
end

function KCompetetive(in::Integer, k::Integer, σ = tanh, α::Float64 = 6.26;
               initW = glorot_uniform, initb = zeros)
  if k > in
    throw(warn("Warning: k (out) should not be larger than dim: $in, found: $k, using $in"))
    k = in
  end
  return KCompetetive(σ, param(initW(k, in)), param(initb(k)), α)
end

treelike(KCompetetive)

function (a::KCompetetive)(x)
  W, b, σ, α = a.W, a.b, a.σ, a.α

  ps = Vector{Tuple{Int64,Float64}}()
  ns = Vector{Tuple{Int64,Float64}}()

  for (i, activation) = enumerate(data(x))
    if activation >= 0
        push!(ps, (i, activation))
    else
        push!(ns, (i, activation))
    end
  end
  ps = sort(ps, by=last)
  ns = sort(ns, by=last, rev=true)
  P = length(ps)
  N = length(ns)
  k = first(size(a.W))

  z = data(x)
  
  p = P-Int(k/2)
  if p > 0
    Epos = sum(map(last, ps[1:p]))
    # @show Epos
    for i = p+1:P
        # positive winners
        z[first(ps[i])] += α * Epos
    end
    for i = 1:p 
        # positive losers
        z[first(ps[i])] = 0.0
    end    
  end

  n = N-Int(k/2)
  if n > 0
    Eneg = sum(map(last, ns[1:n]))
    # @show Eneg
    for i = n+1:N
        # negative winners
        z[first(ns[i])] += α * Eneg
    end
    for i = 1:n
        # negative losers
        z[first(ns[i])] = 0.0
    end    
  end

  #  result = σ.(W*x .+ b)
  #  @show result
  #  result
  σ.(W*x .+ b)
end

function Base.show(io::IO, l::KCompetetive)
  print(io, "KCompetetive(", size(l.W, 2), ", ", size(l.W, 1))
  l.σ == identity || print(io, ", ", l.σ)
  print(io, ")")
end

function non_empty_string(s)
    s != ""
end

function count_words(text::Array{String})
    unique_words = unique(text)
    word_counts = Dict{String,Int64}(map(word -> (word, 0), unique_words))
    map(word -> word_counts[word] += 1, text)
    word_counts
end

function nl(word::String, wc::Dict{String,Int64}, V::Int)
    n = wc[word]
    logwc = log(1+n)
    logwc/V*logwc
end

function normalize_log(text::Array{String}, word_counts::Dict{String,Int64})
    V = length(word_counts)
    map(word -> nl(word,word_counts,V), text)
end

function transform_text_to_input(src::String, limit::Int=1000)
    text_raw = readstring(src)
    text = map(s -> String(s), 
        filter(non_empty_string, split(text_raw, r"[^\wäÄöÖüÜ&]+")))
    text = text[1:limit]
    word_counts = count_words(text)
    input = normalize_log(text, word_counts)
    return input, word_counts
end

function get_similar_words(model, query_id, vocab; topn=10)
    # @show vocab
    W = model[1].W.data
    W = W/norm(W)
    query = W[query_id]
    # @show query
    score = query*(W')
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
