module Index

using DataStructures

function key(kv::Pair)
    kv[1]
end

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

function invert{N<:Number}(itr::Array{N})
    d = Dict{N,Vector{Int64}}()
    keys = unique(itr)
    for key in keys
        d[key] = Int64[]
    end
    for (i, val) in enumerate(itr)
        push!(d[val], i)
    end
    d
end

function pairs{N<:Number}(sequence::Array{N,1};
    unique = true, overlapping = false, gap = -1)

    pairs = Dict{Tuple{N,N},Vector{Tuple{Int64,Int64}}}()

    S = length(sequence)
    for i in 1:S
        for j in i+1:S
            # assert(i<j)
            if gap >= 0 && i+gap+1 < j
                continue
            end
            a,b = sequence[i], sequence[j]
            if unique && a == b
                continue
            end
            pair = (a,b)
            if haskey(pairs, pair)
                if overlapping
                    push!(pairs[pair],(i,j))
                else
                    if pairs[pair][end][2] < i
                        push!(pairs[pair],(i,j))
                    end
                end
            else
                pairs[pair] = [(i,j)]
            end
        end
    end

    DataStructures.OrderedDict(sort(collect(pairs), by=key))
end

end # module Index
