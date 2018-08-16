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


# text = [
#     """2014-12-02 08:28:12,985 WARN  - de.rcenvironment.core.communication.connection.impl.ConnectionSetupImpl - Failed to connect to "129.247.111.209:21000"  (Reason: de.rcenvironment.core.communication.common.CommunicationException: Failed to establish JMS connection. Reason: javax.jms.JMSException: Could not connect to broker URL: tcp://129.247.111.209:21000?keepAlive=true. Reason: java.net.ConnectException: Connection refused, Connection details: activemq-tcp:129.247.111.209:21000(autoRetryDelayMultiplier=1.5, autoRetryInitialDelay=5, autoRetryMaximumDelay=300, connectOnStartup=true))123,123""",
#     """2014-12-02 08:28:28,541 DEBUG - de.rcenvironment.core.component - ServiceEvent REGISTERED - {de.rcenvironment.core.component.execution.api.ComponentExecutionController}={rce.component.execution.id=ecb9b2f6-0c02-4fb9-b0fd-dfb339a17a76, service.id=262} - de.rcenvironment.core.component""",
#     ]

text = readlines("data/datasets/RCE/2014-12-02_08-58-09_1048.log")
text = readlines("data/datasets/RCE/2016-12-14_09-00-53_243818.log")

# text = ["_123.465_"]

labels = [
    (Label("rce_datetime"), r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}", parse_rce_datetime),
    (Label("ipv4"), r"\d{3}\.\d{3}\.\d{3}\.\d{3}", identity),
    (Label("german_float"), r"\d+\,\d+", parse_comma_separated_float),
    (Label("float"), r"\d+\.\d+", parse_float),
    (Label("int"), r"\d+", parse_int),
]

parsed = Vector{Any}(length(text))
for i in eachindex(text)
    parsed[i] = parse(text[i], labels)
    # parsed = @time sort(parsed, by=t->t[1].start)
    # for i in 1:length(parsed)-1
    #     a = parsed[i]
    #     b = parsed[i+1]
    
    #     assert(a[1].stop +1 == b[1].start)
    # end
end
parsed