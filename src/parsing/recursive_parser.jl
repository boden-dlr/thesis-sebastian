using LogClustering.Parsing: Label, LogAttr
using LogClustering.Parsing: parse_comma_separated_float, parse_float, parse_int, parse_rce_datetime
using LogClustering.NLP
using Dates


function Base.parse(line::S, labels::L, slice::UnitRange{Int} = 0:0) where {S<:AbstractString, L<:AbstractArray}

    if length(line) == 0
        return []
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
    matches = collect(
        isempty(m.captures) ? m.match : m.captures[1]
            for m in eachmatch(re, sub))

    if length(matches) == 0
        append!(parsed, parse(line, rest, slice))
    end

    for i in eachindex(matches)
        m = matches[i]

        if i == 1
            from = slice.start
            to = slice.start + m.offset - 1
            if length(from:to) > 0
                append!(parsed, parse(line, rest, from:to))
            end
        end

        from = slice.start + m.offset
        to = slice.start + m.offset + m.ncodeunits - 1
        push!(parsed, (from:to, LogAttr(parse_value(m), m, label, from:to)))

        if i < length(matches)
            from = slice.start + m.offset + m.ncodeunits
            to = slice.start + matches[i+1].offset -1
            if length(from:to) > 0
                append!(parsed, parse(line, rest, from:to))
            end
        else #if i == length(matches)
            from = slice.start + m.offset + m.ncodeunits
            to = slice.stop
            if length(from:to) > 0
                append!(parsed, parse(line, rest, from:to))
            end
        end
    end

    return parsed
end


function tokenize(parsed, splitter)
    log_key = Vector{String}()
    log_vals = Vector{LogAttr}()
    for (pos, token) in parsed
        if token isa LogAttr
            push!(log_key, token.label.label)
            push!(log_vals, token)
        else
            append!(log_key, NLP.split_and_keep_splitter(token, splitter))
        end
    end
    (log_key, log_vals)
end


function extract_time(log_values)
    log_times = fill(0,length(log_values))
    last = nothing
    for i in eachindex(log_values)
        if length(log_values[i]) > 0
            value = log_values[i][1].value
            if value isa Dates.DateTime
                if last == nothing
                    last = value
                end
                log_times[i] = convert(Int64, Dates.value(value - last))
                last = value
            end
        end
    end
    log_times
end


function parse_event_log_recursive(
    text::Vector{String},
    labels::Vector{Tuple{Label,Regex,Parser}},
    splitter::Regex = r"\s+";
    timediff=true) where Parser <: Function

    event_log = Dict(
        :log_keys => Vector{Vector{String}}(),
        :log_values => Vector{Vector{LogAttr}}(),
        )
    
    for i in eachindex(text)
        parsed = parse(text[i], labels)
        (keys, vals) = tokenize(parsed, splitter)
        push!(event_log[:log_keys], keys)
        push!(event_log[:log_values], vals)
    end

    if timediff
        event_log[:log_times] = extract_time(event_log[:log_values])
    end

    EventLog(
        event_log[:log_keys],
        event_log[:log_values],
        event_log[:log_times],
        nothing)
end
