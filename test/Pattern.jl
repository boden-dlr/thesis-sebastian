using Base.Test
using LogClustering.Pattern
using LogClustering.Index
using LogClustering.Sort: isless
using LogClustering.Sequence: flatmap
using DataStructures: OrderedDict

data = Int64[1,2,3,5,4,5,6,1,2,3,7,6,5,4,1,2]

# ----------------------------------------------------------------------
# recurring pattern mining

# result = Pattern.mine_recurring(data,2)

# data = rand(1:100, 5000)
# @time result = Pattern.mine_recurring(data,11)

# ----------------------------------------------------------------------

min_sup     = 1
unique      = false
overlapping = false
gap         = 0
N = Int64
sequence = data
# vertical = OrderedDict(sort(Index.invert(sequence)))
vertical = Index.invert(sequence)
alphabet = collect(keys(vertical))
vertical_pairs = Index.pairs(sequence, gap=gap)
pairs = collect(keys(vertical_pairs))
db = OrderedDict{Vector{N},Vector{Vector{N}}}()
for (key,rs) in collect(vertical_pairs)
    S = length(rs)
    if S < min_sup
        delete!(vertical_pairs, key)
    else        
        k = [e for e in key]
        v = [[p[1],p[2]] for p in rs]
        # @show key, rs, S, k, v
        db[k] = v
    end
end
db
patterns = collect(keys(db))

Pattern.grow_depth_first(
    sequence,
    vertical,
    alphabet,
    vertical_pairs,
    pairs,
    db,
    patterns;
    min_sup = min_sup,
    unique = unique,
    overlapping = overlapping,
    gap = gap
)
