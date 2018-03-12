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
unique      = true
overlapping = false
gap         = 0
N = Int64

# sequence = data
# sequence = rand(1:100, 5000)
data = readcsv("data/kate/51750S_6154V_148N_3K_15E_1234seed_embedded_KATE_clustered_kmeans_51750P_300k.csv")
sequence = map(n->convert(Int64,n), data[:,1])

# TODO:NOTE: JULIA BUG in OrderedDict!
# vertical = OrderedDict(sort(Index.invert(sequence)))

vertical = Index.invert(sequence)
alphabet = sort(collect(keys(vertical)))
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

@time Pattern.grow_depth_first!(
    db,
    patterns,
    sequence,
    vertical,
    alphabet;
    min_sup = min_sup,
    unique = unique,
    overlapping = overlapping,
    gap = gap
)

sort(collect(keys(db)), rev=true)
