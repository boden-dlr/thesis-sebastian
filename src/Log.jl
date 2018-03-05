module Log

using LogClustering.Index

export split_overlapping


struct Occurence
    from::Int64
    to::Int64
    content::Array{String}
end

struct SplitResult
    prefix::Occurence
    suffix::Occurence
    splitted::Dict{String,Occurence}
end


function split_overlapping(text::Array{String}, selector::Regex)
    
    inverted_index = Index.invert(text, selector)

    splitted = Dict{String,Occurence}()

    first_all = length(text)
    last_all = 0
    for key in keys(inverted_index)
        entries = inverted_index[key]
        first::Int64 = entries[1][1]
        last::Int64 = entries[end][1]
        splitted[key] = Occurence(first, last, text[first:last])

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

    SplitResult(prefix, suffix, splitted)
end

end # module Log
