#
# originally from:
#   https://github.com/JuliaCollections/DataStructures.jl/blob/master/src/trie.jl
#
# see:
#   https://juliacollections.github.io/DataStructures.jl/latest/trie.html
#

abstract type AbstractTrie{T} end

TrieKey = Union{AbstractChar,AbstractString,Integer}

mutable struct Trie{E<:TrieKey,T} <: AbstractTrie{T}
    value::T
    children::Dict{E,Trie{E,T}}
    is_key::Bool

    function Trie{E,T}() where {E<:TrieKey,T}
        self = new{E,T}()
        self.children = Dict{E,Trie{E,T}}()
        self.is_key = false
        self
    end

    function Trie{E,T}(ks, vs) where {E<:TrieKey,T}
        t = Trie{E,T}()
        for (k, v) in zip(ks, vs)
            t[k] = v
        end
        return t
    end

    function Trie{E,T}(kv::AbstractDict) where {E<:TrieKey,T}
        t = Trie{E,T}()
        for (k, v) in kv
            t[k] = v
        end
        return t
    end
end

Trie() = Trie{Int64,Nothing}()
Trie(ks::AbstractVector{AbstractVector{E}}, vs::AbstractVector{V}) where {E<:TrieKey,V} = Trie{E,V}(ks, vs)
Trie(kv::AbstractVector{Tuple{AbstractVector{E},V}}) where {E<:TrieKey,V} = Trie{E,V}(kv)
Trie(kv::AbstractDict{AbstractVector{E},V}) where {E<:TrieKey,V} = Trie{E,V}(kv)
Trie(ks::AbstractVector{AbstractVector{E}}) where {E<:TrieKey} = Trie{E,Nothing}(ks, similar(ks, Nothing))

function Base.eltype(t::AbstractTrie{T}) where {T}
    T
end

function Base.eltype(t::Trie{E,T}) where {E,T}
    E,T
end

function Base.setindex!(t::Trie{E,T}, val::T, key::AbstractVector{E}) where {E<:TrieKey,T}
    node = t
    for char in key
        if !haskey(node.children, char)
            node.children[char] = Trie{E,T}()
        end
        node = node.children[char]
    end
    node.is_key = true
    node.value = val
end

function Base.getindex(t::Trie, key::AbstractVector{E}) where E<:TrieKey
    node = subtrie(t, key)
    if node != nothing && node.is_key
        return node.value
    end
    throw(KeyError("key not found: $key"))
end

function subtrie(t::Trie, prefix::AbstractVector{E}) where E<:TrieKey
    node = t
    for char in prefix
        if !haskey(node.children, char)
            return nothing
        else
            node = node.children[char]
        end
    end
    node
end

function Base.haskey(t::Trie, key::AbstractVector{E}) where E<:TrieKey
    node = subtrie(t, key)
    node != nothing && node.is_key
end

function Base.get(t::Trie, key::AbstractVector{E}, notfound) where E<:TrieKey
    node = subtrie(t, key)
    if node != nothing && node.is_key
        return node.value
    end
    notfound
end

function Base.keys(t::Trie, prefix::AbstractVector{E}=E[], found=AbstractVector{E}[]) where E<:TrieKey
    if t.is_key
        push!(found, prefix)
    end
    for (char,child) in t.children
        keys(child, string(prefix,char), found)
    end
    found
end

function keys_with_prefix(t::Trie, prefix::AbstractVector{E}) where E<:TrieKey
    st = subtrie(t, prefix)
    st != nothing ? keys(st,prefix) : []
end

# The state of a TrieIterator is a pair (t::Trie, i::Int),
# where t is the Trie which was the output of the previous iteration
# and i is the index of the current character of the string.
# The indexing is potentially confusing;
# see the comments and implementation below for details.
struct TrieIterator{E<:TrieKey}
    t::Trie
    seq::AbstractVector{E}
end

# At the start, there is no previous iteration,
# so the first element of the state is undefined.
# We use a "dummy value" of it.t to keep the type of the state stable.
# The second element is 0
# since the root of the trie corresponds to a length 0 prefix of str.
Base.start(it::TrieIterator) = (it.t, 0)

function Base.next(it::TrieIterator, state::Tuple)
    t, i = state
    i == 0 && return it.t, (it.t, 1)

    t = t.children[it.seq[i]]
    return (t, (t, i + 1))
end

function Base.done(it::TrieIterator, state::Tuple)
    t, i = state
    i == 0 && return false
    i == length(it.seq) + 1 && return true
    return !(it.seq[i] in keys(t.children))
end

path(t::Trie, seq::AbstractVector{E}) where E<:TrieKey = TrieIterator(t, str)
Base.IteratorSize(::Type{TrieIterator}) = SizeUnknown()
