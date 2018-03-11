module Pattern

using LogClustering.Index
using LogClustering.Index: key
using DataStructures

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


function mine_recurring{N<:Number}(sequence::Array{N,1}, min_sup::Int64 = 1)

    vertical = Index.invert(sequence)
    primer = Index.pairs(sequence, gap=0)

    primer = Dict(filter(kv->length(kv[2])>=min_sup, collect(primer)))

    result = grow(sequence, vertical, primer, min_sup)

    Dict(filter(kv->length(kv[2])>=min_sup, collect(result)))
    
    # DataStructures.OrderedDict(sort(result), by=kv->kv[1][1])
end

end # module Pattern
