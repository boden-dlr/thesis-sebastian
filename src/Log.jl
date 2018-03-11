module Log

using LogClustering.Index

Segment = UnitRange{Int64}
#     from::Int64
#     to::Int64
#     len::Int64
#     # content::Array{String}
# end

struct Segmentation
    beginning::Segment # preamble
    segments::Dict{String,Segment}
    ending::Segment # postlude
end

function isoverlapping(a::UnitRange{Int64}, b::UnitRange{Int64})
    result = false
    if a.start >= b.start && a.start <= b.stop
        result = true
    elseif a.stop >= b.start && a.stop <= b.stop
        result = true
    end
    result
end

function filter_overlapping_ranges!{K}(d::Dict{K,UnitRange{Int64}};
    strategy::Symbol = :keep_greater, strategy_eq = :keep_both)

    assert(strategy in [:keep_lesser, :keep_greater, :keep_none])
    assert(strategy_eq in [:keep_both, :keep_none])

    kvs = collect(d)
    # track the permutations
    seen = Vector{Tuple{K,K}}() 
    for (k,v) in kvs
        for (c,b) in kvs
            if k != c && !((k,c) in seen) && isoverlapping(v,b)
                V = length(v)
                B = length(b)
                # @show k,v,V,c,b,B, V > B, V < B, V == B, strategy
                if strategy == :keep_lesser
                    if V > B
                        delete!(d,k)
                    elseif V < B
                        delete!(d,c)
                    elseif strategy_eq == :keep_none
                        delete!(d,k)
                        delete!(d,c)
                    end
                elseif strategy == :keep_greater
                    if V < B
                        delete!(d,k)
                    elseif V > B
                        delete!(d,c)
                    elseif strategy_eq == :keep_none
                        delete!(d,k)
                        delete!(d,c)
                    end
                elseif strategy == :keep_none
                    delete!(d,k)
                    delete!(d,c)
                end
            end
            push!(seen,(k,c))
            push!(seen,(c,k))
        end
    end
    d
end

function segment(text::Array{String}, selector::Regex; overlapping = true)

    inverted_index = Index.invert(text, selector)

    splitted = Dict{String,Segment}()

    first_all::Int64 = length(text)
    last_all::Int64 = 0
    for key in keys(inverted_index)
        entries = inverted_index[key]
        first::Int64 = entries[1][1]
        last::Int64 = entries[end][1]
        splitted[key] = Segment(first, last) #, last-first+1) #, text[first:last])
        if first < first_all
            first_all = first
        end

        if last > last_all
            last_all = last
        end
    end

    prefix = Segment(1,first_all-1) #, first_all-1-1+1) #,text[1:first_all-1])
    suffix = Segment(last_all+1, length(text)) #, length(text)-last_all) #, text[last_all+1:end])
    if prefix.start == 1 && suffix.start == 1 && prefix.stop == suffix.stop-1 #.content[1:end-1]
        prefix = Segment(1, length(text)) #, length(text)-1+1) #, text)
    end

    if !overlapping
        splitted = filter_overlapping_ranges!(splitted)
    end

    Segmentation(prefix, splitted, suffix)
end

function split_at(data::Array, segmentation::Segmentation)
    segments = vcat(
        [segmentation.beginning],
        collect(values(segmentation.segments)),
        [segmentation.ending])
    N = length(segments)
    splitted = Array{typeof(data)}(N)
    for (i,s) in enumerate(segments)
        splitted[i] = data[s]
    end
    splitted
end

end # module Log
