module Index

function invert(text::Array{Array{String}}, tokens::Array{String})    
    
    inverted_index = Dict{String,Vector{Tuple{Int64,Int64}}}()
    
    for (l,line) in enumerate(text)
        for (w,word) in line
            for key in tokens
                if word == key
                    if haskey(inverted_index, key)
                        push!(inverted_index[key], (l,w))
                    else
                        inverted_index[key] = Vector{Tuple{Int64,Int64}}()
                        push!(inverted_index[key], (l,w))
                    end
                end
            end
        end
    end

    inverted_index
end

function invert(text::Array{Array{String}}, tokens::Array{Regex})    
    
    inverted_index = Dict{String,Vector{Tuple{Int64,Int64}}}()
    
    for (l,line) in enumerate(text)
        for (w,word) in enumerate(line)
            for regex in tokens
                m = match(regex, word)
                if typeof(m) != Void
                    key = m.captures[1]
                    if haskey(inverted_index, key)
                        push!(inverted_index[key], (l,w))
                    else
                        inverted_index[key] = Vector{Tuple{Int64,Int64}}()
                        push!(inverted_index[key], (l,w))
                    end
                end
            end
        end
    end

    inverted_index
end

function invert(text::Array{String}, tokens::Array{Regex})    
    
    inverted_index = Dict{String,Vector{Tuple{Int64,Int64}}}()
    
    for (l,line) in enumerate(text)
        for regex in tokens
            m = match(regex, line)
            if typeof(m) != Void
                key = m.captures[1]
                if haskey(inverted_index, key)
                    push!(inverted_index[key], (l,m.offset))
                else
                    inverted_index[key] = Vector{Tuple{Int64,Int64}}()
                    push!(inverted_index[key], (l,m.offset))
                end
            end
        end
    end

    inverted_index
end

function invert(text::Array{String}, token::Regex)    
    
    inverted_index = Dict{String,Vector{Tuple{Int64,Int64}}}()
    
    for (l,line) in enumerate(text)
        m = match(token, line)
        if typeof(m) != Void
            key = m.captures[1]
            if haskey(inverted_index, key)
                push!(inverted_index[key], (l,m.offset))
            else
                inverted_index[key] = Vector{Tuple{Int64,Int64}}()
                push!(inverted_index[key], (l,m.offset))
            end
        end
    end

    inverted_index
end

function invert(text::Array{Array{String}}, token::String)  
    
    inverted_index = Dict{String,Vector{Tuple{Int64,Int64}}}()
    
    for (l,line) in enumerate(text)
        for (w,word) in enumerate(line)
            if word == token
                if haskey(inverted_index, token)
                    push!(inverted_index[token], (l,w))
                else
                    inverted_index[token] = Vector{Tuple{Int64,Int64}}()
                    push!(inverted_index[token], (l,w))
                end
            end
        end
    end

    inverted_index
end


function pinvert(text::Array{String}, token::Regex)    

    function match_key(t)
        (l, line) = t
        m = match(token, line)
        if typeof(m) != Void
            key = m.captures[1]
            (key, l , m.offset)
        end
    end

    entries = pmap(match_key, enumerate(text))
    entries = filter!(e -> e != nothing, entries)
    
    inverted_index = Dict{String,Vector{Tuple{Int64,Int64}}}()
    for (key, l, w) in entries
        if haskey(inverted_index, key)
            push!(inverted_index[key], (l,w))
        else
            inverted_index[key] = Vector{Tuple{Int64,Int64}}()
            push!(inverted_index[key], (l,w))
        end
    end

    inverted_index
end

end # module Index
