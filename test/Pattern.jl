using Base.Test
using LogClustering.Pattern
using LogClustering.Index
using LogClustering.Sort: isless
using LogClustering.Sequence: flatmap
using DataStructures: OrderedDict
using BenchmarkTools, Compat
using ProfileView

#            A B C E D G E A B C F E E A B D 
data = Int64[1,2,3,5,4,8,5,1,2,3,7,5,5,1,2,4]
#            0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1
#            1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6

sequence = data
# sequence = rand(1:500, 50000)

# ----------------------------------------------------------------------
# recurring pattern mining
# 

# min_sup = 2
# @btime Pattern.mine_recurring(sequence,min_sup)
# sequence = rand(1:100, 5000)
# @time result = Pattern.mine_recurring(sequence,11)


# ----------------------------------------------------------------------
# grow_depth_first!
# 

min_sup     = 1 #round(Int64,50000/2^15)
unique      = false
similar     = true
overlapping = false
gap         = -1
set         = :closed
N = Int64

# data = readcsv("data/kate/51750S_6154V_148N_3K_15E_1234seed_embedded_KATE_clustered_kmeans_51750P_300k.csv")
# sequence = map(n->convert(Int64,n), data[:,1])
# sequence = reverse(sequence)
# consequents = [42]

# TODO:NOTE: JULIA BUG in OrderedDict!
# vertical = OrderedDict(sort(Index.invert(sequence)))


function test_grow_depth_first(sequence)

vertical = Index.invert(sequence)
alphabet = sort(collect(keys(vertical)))
alphabet = [5]
# alphabet = [11,72,119,276]
# vertical_pairs = Index.pairs(sequence, gap=gap)
# pairs = collect(keys(vertical_pairs))
db = OrderedDict{Vector{N},Vector{Vector{N}}}()

timing = Vector()
first = false
# Profile.clear()
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
        # if key in consequents
        #     db[[key]] = collect(map(v->[v], vals))
        # end
        db[[key]] = collect(map(v->[v], vals))
    end
    extend = reverse(collect(map(k->[k],keys(vertical))))
    # extend = [[1]]
    # extend = map(c->[c], consequents)
    # @show extend

    
    if first
        first = false
        Pattern.grow_depth_first!(
            db,
            extend,
            sequence,
            length(sequence),
            vertical,
            alphabet;
            min_sup = min_sup,
            unique = unique,
            similar = similar,
            overlapping = overlapping,
            gap = gap,
            set = set,
        )
    else
        # (_, t, bytes, gctime, memallocs) = @timed 
        @profile Pattern.grow_depth_first!(
            db,
            extend,
            sequence,
            length(sequence),
            vertical,
            alphabet;
            min_sup = min_sup,
            unique = unique,
            similar = similar,
            overlapping = overlapping,
            gap = gap,
            set = set,
        )

        # push!(timing, (t,bytes,gctime,memallocs))
    end
end

# ProfileView.view()

return db, timing
end

db, timing = test_grow_depth_first(sequence)

avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
# avg_memallocs = reduce((p,t)-> p+t[4], Base.GC_Diff(0,0,0,0,0,0,0,0,0), timing) / length(timing)

# for (i,(k,v)) in enumerate(collect(db))
#     println(string(i, "\t", k, "\t\t", v))
# end
length(keys(db))
reduce((p,l)->p+length(l), 0, flatmap(identity, collect(values(db))))

filter(k->length(k)>3,collect(keys(db)))
sort(collect(keys(db)), rev=true)

reverse.(collect(keys(db)))

db


