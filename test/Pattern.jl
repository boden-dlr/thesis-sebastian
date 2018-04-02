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
# sequence = rand(1:100, 5000)
# data = readcsv("data/kate/51750S_6154V_148N_3K_15E_1234seed_embedded_KATE_clustered_kmeans_51750P_300k.csv")
# sequence = map(n->convert(Int64,n), data[:,1])

# TODO:NOTE: JULIA BUG in OrderedDict!
# vertical = OrderedDict(sort(Index.invert(sequence)))

vertical = Index.invert(sequence)
alphabet = sort(collect(keys(vertical)))
vertical_pairs = Index.pairs(sequence, gap=gap)
pairs = collect(keys(vertical_pairs))
db = OrderedDict{Vector{N},Vector{Vector{N}}}()

timing = Vector()
for _ in 1:1
    # db = OrderedDict{Vector{N},Vector{Vector{N}}}()
    # for (key,rs) in collect(vertical_pairs)
    #     S = length(rs)
    #     if S < min_sup
    #         delete!(vertical_pairs, key)
    #     else        
    #         k = [e for e in key]
    #         v = [[p[1],p[2]] for p in rs]
    #         # @show key, rs, S, k, v
    #         db[k] = v
    #     end
    # end
    # extend = collect(keys(db))
    db = OrderedDict{Vector{N},Vector{Vector{N}}}()
    for (key,vals) in collect(vertical)
        # @show key, vals, typeof(vals)
        db[[key]] = collect(map(v->[v], vals))
    end
    extend = reverse(collect(map(k->[k],keys(vertical))))
    @show extend

    (_, t, bytes, gctime, memallocs) = @timed Pattern.grow_depth_first!(
        db,
        extend,
        sequence,
        vertical,
        alphabet;
        min_sup = min_sup,
        unique = unique,
        overlapping = overlapping,
        gap = gap
    )
    
    push!(timing, (t,bytes))
end
avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)

for (i,(k,v)) in enumerate(collect(db))
    println(string(i, "\t", k, "\t\t", v))
end
length(keys(db))
reduce((p,l)->p+length(l), 0, flatmap(identity, collect(values(db))))

filter(k->length(k)>3,collect(keys(db)))
# sort(collect(keys(db)), rev=true)
