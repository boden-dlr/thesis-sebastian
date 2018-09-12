using LogClustering.Index
using LogClustering.Index: key
using LogClustering.EpisodeMining:
    random_utility, local_utility, external_utility, avg_utility

using DataStructures: OrderedDict #, Trie


"""
    A SPADE inspired depth-first search on a vertical db pseudo projection.
"""
function grow_depth_first!(
    db::OrderedDict{Vector{N},Vector{Vector{N}}},
    prefixes::Vector{Vector{N}},
    sequence::Vector{N},
    len::Int64,
    vertical::Dict{N,Vector{N}},
    alphabet::Vector{N}; # TODO: CMAP?
    utility_measure::Union{Nothing,Symbol} = :external, # :external, local, average
    utilities::Union{Nothing,Dict{Int64,Int64},Vector{Int64}} = nothing,
    total_utility       = len,
    min_utility         = 0.0,
    min_sup             = 1,
    max_repetitions     = 0,
    # similar           = true,
    overlapping         = false,    # false == minimal occurences
    max_gap             = 0,        # -1 endless
    max_time_duration   = -1,       # -1 endless
    set         = :all, # [:all, :closed]
    # set_keys    = Set{Int64}[], # TODO: replace with sorted arrays? What performs better?
    # sorted_keys = Vector{Int64}[],
    # positions   = Dict{Int64,Int64}(), # TODO: replace with an array (assignments)
    depth       = 0) where {N<:Number}

    # shared_db = SharedVector{Tuple{Vector{N},Tuple{Int64,Vector{Tuple{Int64,Int64}},Vector{Vector{N}}}}}(P*A)

    for pattern in prefixes # patterns

        if max_time_duration > -1 && length(pattern) > max_time_duration
            continue
        end

        support = length(db[pattern])
        # @show support, pattern
        if support < min_sup
            delete!(db, pattern)
            continue
        end

        if utility_measure != nothing && utilities != nothing
            # println(utility...(utilities, pattern), "\t", pattern)
            if utility_measure == :external && external_utility(utilities, total_utility, pattern) < min_utility
                delete!(db, pattern)
                continue
            elseif utility_measure == :average  && avg_utility(utilities, total_utility, len, pattern) < min_utility
                delete!(db, pattern)
                continue
            elseif utility_measure == :local && local_utility(utilities, pattern) < min_utility
                delete!(db, pattern)
                continue
            end
        end

        # if !similar
        #     # pattern_as_set = Set(pattern)
        #     # if any(s-> intersect(s, pattern_as_set) == pattern_as_set, set_keys)
        #     #     delete!(db, pattern)
        #     #     continue
        #     # else
        #     #     push!(set_keys, pattern_as_set)
        #     # end
        #     p = sort(pattern)
        #     if any(k-> k == p, sorted_keys)
        #         delete!(db, pattern)
        #         continue
        #     else
        #         push!(sorted_keys, p)
        #     end
        # end

        foundat_all = Set{Int64}()
        for s_ext in alphabet
            if max_repetitions > 0
                if max_repetitions == 1
                    if s_ext in pattern
                        continue
                    end
                else
                    if count(e->e == s_ext, pattern) >= max_repetitions
                        continue
                    end
                end
            end
            foundat = Vector{Int64}()
            # s_extension = vcat(pattern, s_ext)
            s_extension = Array{Int64}(undef, depth+2)
            s_extension[1:depth+1] = pattern
            s_extension[end] = s_ext

            # TODO intersect all keys with s_extension

            for i in 1:support # TODO: maybe change fors s_ext/support and use start/end to prune extensions by @view of sequence...
                start = db[pattern][i][end] + 1
                stop = len
                if max_gap >= 0
                    stop = min(len, start + max_gap)
                end

                # from = 1
                # if haskey(positions, s_ext)
                #     from = positions[s_ext]
                # else
                #     positions[s_ext] = start+1
                # end
                for candidate in @views vertical[s_ext]#[from:end]
                    # @show depth, support, n, s_extension, pattern, s_ext, db[pattern], start, stop, max_gap, candidate, foundat
                    if candidate > stop
                        break
                    end

                    if candidate >= start # && candidate <= stop # (implicitly)
                        # occurence = vcat(db[pattern][i], candidate)
                        occurence = Array{Int64}(undef, depth+2)
                        occurence[1:depth+1] = db[pattern][i]
                        occurence[end] = candidate
                        # @show s_ext, start, stop, candidate, pattern, s_extension, occurence
                        if haskey(db, s_extension)
                            if overlapping
                                push!(db[s_extension], occurence)
                                push!(foundat, i)
                            else
                                # if db[s_extension][end][end] < candidate
                                if db[s_extension][end][end] <= db[pattern][i][1] # do not touch this as it generates correct `moSet``
                                    push!(db[s_extension], occurence)
                                    push!(foundat, i)
                                end
                            end
                        else
                            db[s_extension] = [occurence]
                            push!(foundat, i)
                        end
                    end
                end
            end

            if length(foundat) >= min_sup
                union!(foundat_all, foundat)

                grow_depth_first!(
                    db, [s_extension],
                    sequence, len, vertical, alphabet;
                    utility_measure = utility_measure,
                    utilities = utilities,
                    total_utility = total_utility,
                    min_utility = min_utility,
                    min_sup = min_sup,
                    # unique = unique,
                    # unique_n = unique_n,
                    max_repetitions = max_repetitions,
                    # similar = similar,
                    overlapping = overlapping,
                    max_gap = max_gap,
                    max_time_duration = max_time_duration,
                    set = set,
                    # set_keys = set_keys,
                    # sorted_keys = sorted_keys,
                    # positions = positions,
                    depth = depth + 1)
            else
                delete!(db, s_extension)
            end
        end

        # @show foundat_all, pattern
        # if set == :closed && support < min_sup # NOTE: this prunes a lot: support <= min_sup
        # TODO: closed vs. maximal patterns
        # support < or <= min_sup operator should be an option
        # NOTE: created race condition between `s_ext`s without `foundat_all``
        if set == :closed
            # remove found occs from db[pattern]
            d = 0
            for i in sort(collect(foundat_all))
                # @show s_extension, db[s_extension], foundat, i-d, db[pattern]
                if i > d
                    deleteat!(db[pattern],i-d)
                    d += 1
                end
            end
            support = length(db[pattern])
            # @show support, pattern
        end

        support = length(db[pattern])
        if support < min_sup
            delete!(db, pattern)
            # continue
        end
    end

    # filter 1-event episodes
    # if depth == 0
    #     for k in keys(db)
    #         if length(k) == 1
    #             delete!(db, k)
    #         end
    #     end
    # end

    db
end


function generate_lookuptable(vertical::AbstractDict{Int64,Vector{Int64}}, n::Int64)

    m = length(vertical)
    A = sort(collect(keys(vertical)))
    V = Dict(map(ie -> ie[2] => ie[1], enumerate(A)))
    L = fill(-1,m,n)

    for i in 1:m
        occs = vertical[A[i]]
        l = 1
        for k in 1:length(occs)
            for j in l:n
                # @show i,A[i],j,k,occs[k],occs
                if j <= occs[k]
                    L[i,j] = k
                    l += 1
                end
            end
        end
    end

    L,A,V
end


# function findfirst_gte_binarysearch(gte::Int64, sorted::A)
#     n = length(sorted)
#     pivot::Int64 = n/2
#     current = sorted[pivot]
#     last = 0
#     while current >= gte
#         pivot = pivot/2

#     end
# end


function mv_span(
    sequence::Vector{Int};
    prefixes::Union{Nothing, Vector{Vector{Int}}} = nothing,
    utilities::Union{Nothing, Dict{Int,Int}} = nothing,
    utility::Union{Nothing, Symbol} = :external, # [:external, local, average]
    min_utility         = 0.0,  # rel min utility
    min_sup             = 1,    # abs. min support
    max_repetitions     = 0,    # max_rep < 1 --> endless
    max_gap             = 0,    # max_gap == -1 --> endless
    max_time_duration   = -1,   # mtd == -1 --> endless
    min_occurrences     = true, # false --> minimal occurences
    result_set          = :all
    )

    seq_len = length(sequence)
    vertical = Index.invert(sequence)
    vertical = filter(kv->length(kv[2]) >= min_sup, vertical)
    alphabet = map(kv->kv[1], sort(collect(vertical),
                                   by = kv -> length(kv[2]),
                                   rev=true))
    total_utility = 0
    if utilities != nothing
        total_utility = sum(e->utilities[e], sequence)
    end

    db = OrderedDict{Vector{Int64},Vector{Vector{Int64}}}()
    for (key, values) in collect(vertical)
        db[[key]] = collect(map(v->[v], values))
    end

    if prefixes == nothing
        prefixes = sort(collect(keys(db)), by = k -> length(db[k]))
    end

    grow_depth_first!(
        db,
        prefixes,
        sequence,
        seq_len,
        vertical,
        alphabet;
        utility_measure     = utility,
        utilities           = utilities,
        total_utility       = total_utility,
        min_utility         = min_utility,
        min_sup             = min_sup,
        max_repetitions     = max_repetitions+1,
        overlapping         = !min_occurrences,
        max_gap             = max_gap,
        max_time_duration   = max_time_duration,
        set                 = result_set)

    # filter 1-event episodes
    if min_occurrences
        for k in keys(db)
            if length(k) == 1
                delete!(db, k)
            end
        end
    end

    return db
end
