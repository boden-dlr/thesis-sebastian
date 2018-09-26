include(joinpath(pwd(), "src/datastructures/trie.jl"))

# t = Trie()
# t["Rob"] = 42
# t["Roger"] = 24
# haskey(t, "Rob")  # true
# get(t, "Rob", nothing)  # 42
# keys(t)  # "Rob", "Roger"
# keys(subtrie(t, "Ro"))  # "b", "ger"

chars = ['H', 'e', 'l', 'l', 'o']

t1 = Trie{Char,Nothing}([chars], [nothing])
@assert haskey(t1, chars) == true

# random values for non-key nodes
t2 = Trie{Char,Int}([chars], [42])
@assert haskey(t2, chars) == true

subtrie(t2, ['H', 'e'])

path(t2, chars)
