module Pattern

using LogClustering.Index
using LogClustering.Index: key
using DataStructures: OrderedDict

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


function grow_depth_first!{N<:Number}(
    db::OrderedDict{Vector{N},Vector{Vector{N}}},
    extend::Vector{Vector{N}},
    sequence::Vector{N},
    vertical::Dict{N,Vector{N}},
    alphabet::Vector{N};
    min_sup     = 1,
    unique      = false,
    overlapping = false,
    gap         = -1)
    # TODO: periodicity: min_periodicity:max_periodicity

    # A = length(alphabet)
    # P = length(patterns)

    # shared_db = SharedVector{Tuple{Vector{N},Tuple{Int64,Vector{Tuple{Int64,Int64}},Vector{Vector{N}}}}}(P*A)

    for pattern in extend # patterns
        support = length(db[pattern])
        if support < min_sup
            delete!(db, pattern)
            continue
        end
        for s_ext in alphabet
            if unique && s_ext in pattern
                continue
            end
            foundat = Vector{Int64}()
            s_extension = vcat(pattern, s_ext)
            for n in 1:support-1
                # @show s_extension, pattern, db[pattern]
                start = db[pattern][n][end] + 1
                stop  = db[pattern][n+1][1] - 1
                for candidate in vertical[s_ext]
                    if candidate > stop
                        break
                    end
                    if candidate >= start && candidate <= stop 
                        add = false
                        if gap == -1
                            add = true
                        elseif gap >= 0 && candidate <= start+gap
                            add = true
                        end
                        if add
                            occurence = vcat(db[pattern][n], candidate)
                            # @show pattern, s_ext, candidate, start, stop
                            # @show s_extension, occurence
                            if haskey(db, s_extension)
                                if overlapping
                                    push!(db[s_extension], occurence)
                                    push!(foundat, n)
                                else
                                    if db[s_extension][end][end] < candidate
                                        push!(db[s_extension], occurence)
                                        push!(foundat, n)
                                    end
                                end
                            else
                                db[s_extension] = [occurence]
                                push!(foundat, n)
                            end
                        end
                    end
                end
            end

            # TODO: remove found occs from db[pattern]?
            # d = 0
            # for i in foundat
            #     @show s_extension, foundat, db[pattern]
            #     deleteat!(db[pattern],i-d)
            #     d += 1
            # end
            # support = length(db[pattern])

            if length(foundat) > 0
                grow_depth_first!(
                    db, [s_extension],
                    sequence, vertical, alphabet;
                    min_sup = min_sup,
                    unique = unique,
                    overlapping = overlapping,
                    gap = gap)
            end
        end
        # TODO: remove patterns with support < min_sup
        
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
