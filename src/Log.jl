module Log
export split_overlapping

function split_overlapping(text::Array{String}, selector::Regex)
    
    inverted_index = Dict{String,Vector{Tuple{Int64,Int64}}}()

    for (i, line) in enumerate(text)
        m::RegexMatch = match(selector, line)
        if !(isnull(m))
            key = m.captures[1]
            if haskey(inverted_index, key)
                push!(inverted_index[key], (i, m.offset))
            else
                inverted_index[key] = Vector{Tuple{Int64,Int64}}()
                push!(inverted_index[key], (i, m.offset))
            end
        end
    end

    @show inverted_index

    splitted = Dict{String,Array{String}}()

    for key in keys(inverted_index)
        entries = inverted_index[key]
        first::Int64 = entries[1][1]
        last::Int64 = entries[end][1]
        splitted[key] = text[first:last]
    end

    splitted
end

end # module Log