module Pattern

using LogClustering.Index
using LogClustering.Index: key
using DataStructures: OrderedDict, Trie
# using Compat

#TODO Tuple/Array => (support, range, occs)
# change dict in place!
# support -> filterby
# range -> filterby
# occs -> store
# deüth frist vs. breath first vs. parallel combination

function grow{N<:Number}(sequence::Array{N,1}, vertical, primer, min_sup; overlapping = false)
    #TODO: inter vs intra overlapping...

    extended = Dict{Array{N,1},Array{Tuple{Int64,Int64},1}}()

    for pattern in keys(primer)
        # TODO: try only alphabet elems...
        # for elem in keys(vertical) # alphabet NOTE: if unique filter by pattern elements
        for i in 1:length(primer[pattern])-1
            start = primer[pattern][i][2]+1
            stop = primer[pattern][i+1][1]-1
            for e in start:stop # TODO: try only alphabet elems...
                vertical_s_extension = sequence[e]
                for candidate in vertical[vertical_s_extension]
                    if candidate >= start && candidate <= stop
                        # @show "yeah", pattern, sequence[candidate], candidate
                        s_extended = vcat([p for p in pattern], [sequence[candidate]])
                        if haskey(extended, s_extended)
                            # push!(extended[s_extended], (primer[pattern][i][1], candidate))
                            if overlapping && !((primer[pattern][i][1], candidate) in extended[s_extended])
                                push!(extended[s_extended], (primer[pattern][i][1], candidate))
                            else
                                if extended[s_extended][end][2] < i
                                    push!(extended[s_extended], (primer[pattern][i][1], candidate))
                                end
                            end
                        else
                            extended[s_extended] = [(primer[pattern][i][1], candidate)]
                        end
                    end
                end
            end
        end
    end

    extended = Dict(filter(kv->length(kv[2])>=min_sup, collect(extended)))

    if length(extended) > 0
        future = grow(sequence, vertical, extended, min_sup)
        for pattern in keys(future)
            extended[pattern] = future[pattern]
        end
    end

    for pattern in keys(primer)
        extended[[p for p in pattern]] = primer[pattern]
    end

    extended
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

function random_utility(e)
    rand()
end


function local_utility(utilities, episode)
    u_sum = 0
    local_max = 0
    for e in episode
        u = utilities[e]
        u_sum += u
        if u > local_max
            local_max = u
        end
    end
    u_sum / (length(episode) * local_max)
end


function external_utility(utilities, total_utility, episode)
    u_sum = 0
    for e in episode
        u_sum += utilities[e]
    end
    u_sum / total_utility
end

function avg_utility(utilities, total_utility, len, episode)
    u_sum = 0
    for e in episode
        u_sum += utilities[e]
    end
    # (u_sum / length(episode) * total_utility / len) / total_utility
    min(1.0, (u_sum / length(episode) / len))
end


function grow_depth_first!{N<:Number}(
    db::OrderedDict{Vector{N},Vector{Vector{N}}},
    extend::Vector{Vector{N}},
    sequence::Vector{N},
    len::Int64,
    vertical::Dict{N,Vector{N}},
    alphabet::Vector{N}; # TODO: CMAP?
    utilities::Union{Void,Dict{Int64,Int64}} = nothing,
    total_utility = len,
    min_utility = 0.0,
    min_sup     = 1,
    unique      = false,
    unique_n    = 1,
    similar     = true,
    overlapping = false,
    gap         = 0, # -1 endless
    set         = :all, # [:all, :closed, :maximal] closed vs. maximal?!
    # set_keys    = Set{Int64}[], # TODO: replace with sorted arrays? What performs better?
    sorted_keys = Vector{Int64}[],
    # positions   = Dict{Int64,Int64}(), # TODO: replace with an array (assignments)
    depth       = 0) 

    # shared_db = SharedVector{Tuple{Vector{N},Tuple{Int64,Vector{Tuple{Int64,Int64}},Vector{Vector{N}}}}}(P*A)

    for pattern in extend # patterns
        support = length(db[pattern])
        # @show support, pattern
        if support < min_sup
            delete!(db, pattern)
            continue
        end

        # println(avg_utility(utilities, total_utility, len, pattern), "\t", pattern)
        # if utilities != nothing && avg_utility(utilities, total_utility, len, pattern) < min_utility
        # println(local_utility(utilities, pattern), "\t", pattern)
        if utilities != nothing && local_utility(utilities, pattern) < min_utility
            delete!(db, pattern)
            continue
        end
        
        if !similar
            # pattern_as_set = Set(pattern)
            # if any(s-> intersect(s, pattern_as_set) == pattern_as_set, set_keys)
            #     delete!(db, pattern)
            #     continue
            # else
            #     push!(set_keys, pattern_as_set)
            # end
            p = sort(pattern)
            if any(k-> k == p, sorted_keys)
                delete!(db, pattern)
                continue
            else
                push!(sorted_keys, p)
            end
        end

        foundat_all = Set{Int64}()
        for s_ext in alphabet
            if unique
                if unique_n <= 1
                    if s_ext in pattern
                        continue
                    end
                else
                    if count(e->e == s_ext, pattern) >= unique_n
                        continue
                    end
                end
            end
            foundat = Vector{Int64}()
            s_extension = vcat(pattern, s_ext)

            # TODO intersect all keys with s_extension

            for i in 1:support # TODO: maybe change fors s_ext/support and use start/end to prune extensions by @view of sequence...
                start = db[pattern][i][end] + 1
                stop = len
                if gap >= 0
                    stop = min(len, start + gap)
                end

                # from = 1
                # if haskey(positions, s_ext)
                #     from = positions[s_ext]
                # else
                #     positions[s_ext] = start+1
                # end
                for candidate in vertical[s_ext]#[from:end]
                    # @show depth, support, n, s_extension, pattern, s_ext, db[pattern], start, stop, gap, candidate, foundat
                    if candidate > stop
                        break
                    end
                    
                    if candidate >= start # && candidate <= stop # (implicitly)
                        occurence = vcat(db[pattern][i], candidate)
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
                    utilities = utilities,
                    total_utility = total_utility,
                    min_utility = min_utility,
                    min_sup = min_sup,
                    unique = unique,
                    unique_n = unique_n,
                    similar = similar,
                    overlapping = overlapping,
                    gap = gap,
                    set = set,
                    # set_keys = set_keys,
                    sorted_keys = sorted_keys,
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
        if set in [:closed,:maximal]
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
    if depth == 0
        for k in keys(db)
            if length(k) == 1
                delete!(db, k)
            end
        end
    end

    db
end


function mine_recurring{N<:Number}(sequence::Array{N,1}, min_sup::Int64 = 1)

    vertical = Index.invert(sequence)
    primer = Index.pairs(sequence, gap=0)

    primer = Dict(filter(kv->length(kv[2])>=min_sup, collect(primer)))

    result = grow(sequence, vertical, primer, min_sup)

    Dict(filter(kv->length(kv[2])>=min_sup, collect(result)))

    # DataStructures.OrderedDict(sort(result), by=kv->kv[1][1])
end


function generate_lookuptable(vertical::Associative{Int64,Vector{Int64}}, n::Int64)

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


end # module Pattern
