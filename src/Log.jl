module Log

using NamedTuples

export split_overlapping

function split_overlapping(text::Array{String}, selector::Regex)
    
    inverted_index = Dict{String,Vector{Tuple{Int64,Int64}}}()

    for (i, line) in enumerate(text)
        m = match(selector, line)
        if typeof(m) != Void
            key = m.captures[1]
            if haskey(inverted_index, key)
                push!(inverted_index[key], (i, m.offset))
            else
                inverted_index[key] = Vector{Tuple{Int64,Int64}}()
                push!(inverted_index[key], (i, m.offset))
            end
        end
    end

    splitted = Dict{String,Array{String}}()

    first_all = length(text)
    last_all = 0
    for key in keys(inverted_index)
        entries = inverted_index[key]
        first::Int64 = entries[1][1]
        last::Int64 = entries[end][1]
        splitted[key] = text[first:last]

        if first < first_all
            first_all = first
        end

        if last > last_all
            last_all = last
        end
    end

    prefix = text[1:first_all-1]
    suffix = text[last_all+1:end]

    @NT(prefix=prefix, splitted=splitted, suffix=suffix)
end

end # module Log
