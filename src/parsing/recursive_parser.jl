using LogClustering.Parsing: Label, LogAttr
using LogClustering.Parsing: parse_comma_separated_float, parse_float, parse_int, parse_rce_datetime


function Base.parse(line::S, labels::L, slice::UnitRange{Int} = 0:0) where {S<:AbstractString, L<:AbstractArray}

    if length(line) == 0
        return nothing
    end

    if slice.start == 0
        slice = 1:length(line)
    end
    
    sub = SubString(line, slice.start, slice.stop)

    if length(labels) == 0
        return [(slice, sub)]
    end

    parsed = Vector{Any}()
    (label, re, parse_value) = labels[1]
    rest = @views labels[2:end]
    matches = matchall(re, sub)

    if length(matches) == 0
        append!(parsed, parse(line, rest, slice))
    end

    for i in eachindex(matches)
        m = matches[i]

        # @show m
        add = true
        left = m.offset
        if left > 0
            # @show sub[left:left]
            left_boundary = match(r"\b|\_", @views sub[left:left])
            if left_boundary != nothing
                add = false
            end
        end
        right = m.offset+m.endof+1
        if add && right < length(sub)
            # @show sub[right:right]
            right_boundary = match(r"\_|\b", @views sub[right:right])
            if right_boundary != nothing
                add = false
            end
        end

        if i == 1
            from = slice.start
            to = slice.start + m.offset - 1
            if length(from:to) > 0
                append!(parsed, parse(line, rest, from:to))
            end
        end

        from = slice.start + m.offset
        to = slice.start + m.offset + m.endof - 1
        if add    
            push!(parsed, (from:to, LogAttr(parse_value(m), m, label)))
        else
            push!(parsed, (from:to, SubString(line, from, to)))
        end
        
        if i < length(matches)
            from = slice.start + m.offset + m.endof
            to = slice.start + matches[i+1].offset -1
            if length(from:to) > 0
                append!(parsed, parse(line, rest, from:to))
            end
        else #if i == length(matches)
            from = slice.start + m.offset + m.endof
            to = slice.stop
            if length(from:to) > 0
                append!(parsed, parse(line, rest, from:to))
            end
        end
    end

    return parsed 
end

