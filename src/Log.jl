module Log

using NamedTuples
using AutoHashEquals

export split_overlapping

@auto_hash_equals struct Occurence
    from::Int64
    to::Int64
    content::Array{String}
end

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

    splitted = Dict{String,Occurence}()

    first_all = length(text)
    last_all = 0
    for key in keys(inverted_index)
        entries = inverted_index[key]
        first::Int64 = entries[1][1]
        last::Int64 = entries[end][1]
        splitted[key] = Occurence(
            first,
            last,
            text[first:last]
        )

        if first < first_all
            first_all = first
        end

        if last > last_all
            last_all = last
        end
    end

    prefix = Occurence(1,first_all-1,text[1:first_all-1])
    suffix = Occurence(last_all+1, length(text), text[last_all+1:end])
    if prefix.content == suffix.content[1:end-1]
        prefix = Occurence(1, length(text), text)
    end

    @NT(prefix=prefix, splitted=splitted, suffix=suffix)
end

end # module Log
