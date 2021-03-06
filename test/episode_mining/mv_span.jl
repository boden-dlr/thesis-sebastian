using Test

using LogClustering.EpisodeMining
using LogClustering.Index
using LogClustering.Sort: isless
using LogClustering.Sequence: flatmap

using DataStructures: OrderedDict, Trie
# using BenchmarkTools, Compat
# using ProfileView

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
options = OrderedDict(
    :utility_measure => nothing,    #:external :local :average
    :min_utility     => 0.000025,   # external:0.000025, local:0.999, :average=0.1-0.05,
    :min_sup         => 1,
    :max_rep         => 1,          # n < 1 --> endless
    # :similar         => true,
    :max_gap         => 0,          # n = -1 --> endless
    :max_td          => -1,         # n = -1 --> endless
    :min_occs        => true,       # min occs only
    :set             => :all)

# data = readcsv("data/kate/51750S_6154V_148N_3K_15E_1234seed_embedded_KATE_clustered_kmeans_51750P_300k.csv")
# data = readdlm("data/embedding/playground/2018-07-25_51750_assignments.csv")
# data = readdlm("data/embedding/playground/2018-07-25_51750_assignments_and_reconstruction_error.csv")
# sequence = map(n->convert(Int64,n), data[:,1])

# sequence = reverse(sequence)
# sequence = reverse(sequence)
# consequents = [5]

vertical = Index.invert(sequence)
alphabet = map(kv->kv[1], sort(collect(vertical),
                               by = kv -> length(kv[2]),
                               rev=true))
utilities = nothing
total_utility = 1
# utilities = Dict{Int64,Int64}(map(k -> k => k, alphabet))
# max_occ = maximum(map(length,values(vertical)))
# utilities = Dict{Int64,Int64}(map(k -> k => 1 + max_occ - length(vertical[k]), alphabet))
utilities = Dict{Int64,Int64}(map(k -> k => length(vertical[k]), alphabet))
total_utility = sum(e->utilities[e], sequence)

# alphabet = [5]
# alphabet = [11,72,119,276]
# alphabet = [701]
# vertical_pairs = Index.pairs(sequence, gap=gap)
# pairs = collect(keys(vertical_pairs))

vertical = filter(kv->length(kv[2]) >= options[:min_sup], vertical)
alphabet = map(kv->kv[1], sort(collect(vertical),
                               by = kv -> length(kv[2]),
                               rev=true))


function test_grow_depth_first(vertical, alphabet)

    db = OrderedDict{Vector{Int64},Vector{Vector{Int64}}}()

    timing = Vector()
    first = true
    # Profile.clear()
    for _ in 1:1
        # db = OrderedDict{Vector{Int64},Vector{Vector{Int64}}}()
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
        db = OrderedDict{Vector{Int64},Vector{Vector{Int64}}}()
        for (key,vals) in collect(vertical)
            # @show key, vals, typeof(vals)
            db[[key]] = collect(map(v->[v], vals))
            # if key in consequents
            #     db[[key]] = collect(map(v->[v], vals))
            # end
        end
        # extend = reverse(collect(map(k->[k],keys(vertical))))
        # extend = reverse(collect(keys(db)))
        extend = sort(collect(keys(db)))
        # extend = [[5,1,2]]
        # extend = map(c->[c], consequents)
        # @show extend

        if first
            first = false
            db = EpisodeMining.mv_span(
                sequence,
                prefixes          = extend,
                utilities         = utilities,
                utility           = options[:utility_measure],
                min_utility       = options[:min_utility],
                min_sup           = options[:min_sup],
                max_repetitions   = options[:max_rep],
                max_gap           = options[:max_gap],
                max_time_duration = options[:max_td],
                min_occurrences   = options[:min_occs],
                result_set        = options[:set])
        else
            # @profile
            (db, t, bytes, gctime, memallocs) = @timed EpisodeMining.mv_span(
                sequence,
                prefixes          = extend,
                utilities         = utilities,
                utility           = options[:utility_measure],
                min_utility       = options[:min_utility],
                min_sup           = options[:min_sup],
                max_repetitions   = options[:max_rep],
                max_gap           = options[:max_gap],
                max_time_duration = options[:max_td],
                min_occurrences   = options[:min_occs],
                result_set        = options[:set])

            push!(timing, (t,bytes,gctime,memallocs))
        end
    end

    # ProfileView.view()

    return db, timing
end

db, timing = test_grow_depth_first(vertical, alphabet)

avg_time  = reduce((p,t)-> p+t[1], timing, init=0.0) / length(timing)
avg_bytes = reduce((p,t)-> p+t[2], timing, init=0.0) / length(timing)
avg_gctime = reduce((p,t)-> p+t[3], timing, init=0.0) / length(timing)
avg_poolalloc = reduce((p,t)-> p+t[4].poolalloc, timing, init=0) / length(timing)

length(keys(db))
reduce((p,l)->p+length(l), flatmap(identity, collect(values(db))), init=0)

sort(filter(v -> v!=nothing,
    map(k -> length(db[k]) >= options[:min_sup] ? (length(db[k]),length(k),k) : nothing, # db[k]
        filter(k -> length(k) >= 3, collect(keys(db)))))
    , by = x->x[1])

# sort(collect(keys(db)), rev=true)

# reverse.(collect(keys(db)))

# for (i,(k,v)) in enumerate(collect(db))
#     println(string(i, "\t", k, "\t\t", v))
# end

db

# while true
#     sleep(5)
# end
