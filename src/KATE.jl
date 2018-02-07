module KATE

using Flux
using Flux: onehot, argmax, chunk, batchseq, throttle, crossentropy, sigmoid, treelike, glorot_uniform
using Flux.Tracker: data
using StatsBase: wsample
using Base.Iterators: partition

function non_empty_string(s)
    s != ""
end

function count_words(text::Array{String})
    unique_words = unique(text)
    word_counts = Dict{String,Int64}(map(word -> (word, 0), unique_words))
    map(word -> word_counts[word] += 1, text)
    word_counts
end

function normalize_log(text::Array{String}, word_counts::Dict{String,Int64})
    V = length(word_counts)

    function nl(word::String, wc::Dict{String,Int64}, V::Int)
        n = wc[word]
        logwc = log(1+n)
        logwc/V*logwc
    end

    map(word -> nl(word,word_counts,V), text)
end

function normalize_input(src::String, limit::Int=1000)
    text_raw = readstring(src)
    text = map(s -> String(s), 
        filter(non_empty_string, split(text_raw, r"[^\wäÄöÖüÜ&]+")))
    text = text[1:limit]
    word_counts = count_words(text)
    input = normalize_log(text, word_counts)
    return input, word_counts
end

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

  # @show x
  # @show typeof(x), length(x)
  
  ps = Vector{Float64}()
  ns = Vector{Float64}()

  for (i, activation) = enumerate(data(x))
    if activation >= 0
        push!(ps, activation)
    else
        push!(ns, activation)
    end
  end
  ps = sort(ps)
  ns = sort(ns,rev=true)
  P = length(ps)
  N = length(ns)
  k = last(size(a.W))
  # @show ps, ns
  # @show typeof(ps), typeof(ns)
  # @show P, N, k, k==P+N, size(W)
  
  p = P-Int(k/2)
  if p > 0
    Epos = sum(ps[1:p])
    for i = p+1:P
        ps[i] += α * Epos
    end
    for i = 1:p 
        ps[i] = 0.0
    end    
  end

  n = N-Int(k/2)
  if n > 0
    Eneg = sum(ns[1:n])
    for i = n+1:N
        ns[i] += α * Eneg
    end
    for i = 1:n
        ns[i] = 0.0
    end    
  end
  
  z = param(vcat(reverse(ps),ns))
  # z = param(rand(k))
  # z = x
  # @show z
  # @show typeof(z), length(z), p, n

  σ.(W*z .+ b)
end

function Base.show(io::IO, l::KCompetetive)
  print(io, "KCompetetive(", size(l.W, 2), ", ", size(l.W, 1))
  l.σ == identity || print(io, ", ", l.σ)
  print(io, ")")
end

end # module KATE
