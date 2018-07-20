module Pattern

using LogClustering.Index
using LogClustering.Index: key
using DataStructures: OrderedDict
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


function grow_depth_first!{N<:Number}(
    db::OrderedDict{Vector{N},Vector{Vector{N}}},
    extend::Vector{Vector{N}},
    sequence::Vector{N},
    len::Int64,
    vertical::Dict{N,Vector{N}},
    alphabet::Vector{N}; # TODO: CMAP?
    min_sup     = 1,
    unique      = true,
    similar     = true,
    overlapping = false,
    gap         = 0, # -1 endless
    set         = :closed, # 'maximal' 'all'
    set_keys    = Set{Int64}[], # TODO: replace with sorted arrays
    # positions   = Dict{Int64,Int64}(), # TODO: replace with an array (assignments)
    depth       = 0) 
    # TODO: periodicity: min_periodicity:max_periodicity

    # A = length(alphabet)
    # P = length(patterns)

    # shared_db = SharedVector{Tuple{Vector{N},Tuple{Int64,Vector{Tuple{Int64,Int64}},Vector{Vector{N}}}}}(P*A)

    for pattern in extend # patterns
        support = length(db[pattern])
        # @show support, pattern
        if support < min_sup
            delete!(db, pattern)
            continue
        end
        
        # if !similar
        #     pattern_as_set = Set(pattern)
        #     if any(s-> intersect(s, pattern_as_set) == pattern_as_set, set_keys)
        #         delete!(db, pattern)
        #         continue
        #     else
        #         push!(set_keys, pattern_as_set)
        #     end
        # end

        foundat_all = Set{Int64}()
        for s_ext in alphabet
            if unique && s_ext in pattern
                continue
            end
            foundat = Vector{Int64}()
            s_extension = vcat(pattern, s_ext)
            # if s_ext in [3,4,5] @show "1", s_extension, pattern, db[pattern], support end

            # TODO intersect all keys with s_extension

            for i in 1:support # TODO: maybe change fors s_ext/support and use start/end to prune extensions by @view of sequence...
                # if s_ext == 5 @show s_extension, n end
                start = db[pattern][i][end] + 1
                # stop = start+1
                stop = len
                if gap >= 0
                    stop = min(len, start + gap)
                end
                # if n != support
                #     # stop = db[pattern][n+1][1] - 1
                #     if unique || !overlapping
                #         stop = db[pattern][end][1] - 1
                #         # stop = db[pattern][end][1]
                #     else
                #         stop = db[pattern][end][1]
                #         # stop = len  # maybe always until `len`?
                #     end
                # end
                # @show start, stop, s_ext, vertical[s_ext]
                # from = Compat.findfirst(x -> x >= start, vertical[s_ext])
                # if from == nothing # for v0.6 and v0.7
                #     break
                # end
                # from = 1
                # if haskey(positions, s_ext)
                #     from = positions[s_ext]
                # else
                #     positions[s_ext] = start+1
                # end
                for candidate in vertical[s_ext]#[from:end]
                    # if s_ext == 5 @show s_extension, candidate, start, stop, gap end
                    # @show depth, support, n, s_extension, pattern, s_ext, db[pattern], start, stop, gap, candidate, foundat
                    # if s_ext in [3,4,5] @show "1.2", n, s_extension, candidate, start, stop, gap end
                    if candidate > stop
                        break
                    end
                    
                    if candidate >= start # && candidate <= stop #implicit
                        # add = false
                        # # if s_ext in [3,4,5] @show "2", s_extension, candidate, start, stop, gap end
                        # if gap == -1
                        #     add = true
                        # # NOTE: this prunes a lot!
                        # # elseif gap >= 0 && candidate <= start+gap
                        # elseif gap >= 0 && candidate <= stop
                        #     # if s_ext in [3,4,5] @show "3", s_extension, candidate, start, stop, gap end
                        #     add = true
                        # end
                        # # println()
                        # if add
                        occurence = vcat(db[pattern][i], candidate)
                        # @show pattern, s_ext, candidate, start, stop
                        # @show s_extension, occurence
                        if haskey(db, s_extension)
                            if overlapping
                                push!(db[s_extension], occurence)
                                push!(foundat, i)
                            else
                                if db[s_extension][end][end] < candidate # do not touch this
                                    push!(db[s_extension], occurence)
                                    push!(foundat, i)
                                end
                            end
                        else
                            db[s_extension] = [occurence]
                            push!(foundat, i)
                        end
                        # println.(collect(db))
                        #@show depth, s_extension, pattern, s_ext
                        #@show occurence, foundat, candidate, start, stop
                        #println("end: add")
                        # end
                        #println("end: if candidate")
                    end
                    #println("end: for candidate: $candidate")
                end
                #println("end: support")
            end

            if length(foundat) >= min_sup
                union!(foundat_all, foundat)

                grow_depth_first!(
                    db, [s_extension],
                    sequence, len, vertical, alphabet;
                    min_sup = min_sup,
                    unique = unique,
                    similar = similar,
                    overlapping = overlapping,
                    gap = gap,
                    set = set,
                    set_keys = set_keys,
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

end # module Pattern
