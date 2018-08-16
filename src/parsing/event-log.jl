using LogClustering: NLP
using LogClustering.Parsing: Label

using DataStructures: OrderedDict

struct LogAttr{T,S<:AbstractString,L<:Union{Label,Void}}
    value::T
    source::S
    label::L
end

function LogAttr(value, source)
    LogAttr(value, source, nothing)
end

mutable struct EventLog
    log_keys::Vector{Vector{String}}
    log_values::Vector{Vector{LogAttr}}
    log_times::Vector{Int64}
    embeddings::Union{Vector{Vector{Float64}},Void}
end

function parse_event_log(document::Vector{String};
    line_parser::Union{Vector{Tuple{Label,Regex,ParseFunction}},Void} = nothing,
    word_parser::Union{Vector{Tuple{Label,Regex,ParseFunction}},Void} = nothing,
    line_splitter::Regex = r"\s+",
    label_chars::Regex = r"[\*\%]",
    label_char_replacement::Char = '_',
    label_single::Char = '*',
    label_multi::Char = '%',
    join_log_keys::Bool = false) where ParseFunction <: Function

    document = deepcopy(document)

    single = string(label_single)
    multi = string(label_multi)

    log_keys   = Vector{Vector{String}}(length(document))
    log_values = Vector{Vector{LogAttr}}(length(document))

    omit = Regex(string("[",label_single,label_multi,"]"))

    # stage 1 - per line
    if line_parser != nothing && length(line_parser) == 0
        warn("empty line parser")
    else
        for l in eachindex(document)
            line = document[l]
            if length(line) == 0
                log_keys[l] = NLP.split_and_keep_splitter(line, line_splitter)
                log_values[l] = Vector{LogAttr}()
            else
                line = replace(line, label_chars, label_char_replacement)
                parsed_values = Vector{Pair{Int64,LogAttr}}()
                for (label, re, pf) in line_parser
                    values = matchall(re, line)
                    if any(v->contains(v, omit), values)
                        continue
                    end
                    for i in eachindex(values)
                        v = values[i]
                        push!(parsed_values, v.offset => LogAttr(pf(v),v,label))
                    end
                    line = replace(line, re, label.label)
                end

                words = NLP.split_and_keep_splitter(line, line_splitter)
                log_keys[l] = words

                # stage 2 - per word
                if word_parser != nothing && length(word_parser) > 0    
                    ws = Vector{String}()
                    pos = 0
                    for word in words
                        pos += length(word)
                        for (label, re, pf) in word_parser
                            values = matchall(re, word)
                            if any(v->contains(v, omit), values)
                                continue
                            end
                            for i in eachindex(values)
                                v = values[i]
                                push!(parsed_values, pos+v.offset => LogAttr(pf(v),v,label))
                            end
                            word = replace(word, re, label.label)
                        end
                        push!(ws, word)
                    end
                    log_keys[l] = ws
                end
                parsed_values = sort(parsed_values, by=kv->kv[1])

                log_values[l] = map(kv -> kv[2], parsed_values)
            end
        end
    end

    log_times = fill(0,length(document))
    last = nothing
    for i in eachindex(log_values)
        if length(log_values[i]) > 0
            value = log_values[i][1].value
            if value isa Base.Dates.DateTime
                if last == nothing
                    last = value
                end
                log_times[i] = convert(Int64, Dates.value(value - last))
                last = value
            end
        end
    end

    if join_log_keys == true
        for i in eachindex(log_keys)
            log_keys[i] = [join(log_keys[i],"")]
        end
    end

    EventLog(
        log_keys,
        log_values,
        log_times,
        nothing)
end

function normalize_log_keys(event_log::EventLog)
    vocab = NLP.count_terms(event_log.log_keys)
    data = NLP.normalize_by_max_count(event_log.log_keys, vocab)

    lkl = map(length, event_log.log_keys)
    max = maximum(lkl)
    s = lkl ./ max
    # hcat(s, data .* s, s)

    # data
    # hcat(s, data .* s, s)
    hcat(s, data)
end

function normalize_log_values(event_log::EventLog, time_diff=true)
    values = Vector{String}[
        map(attr -> convert(String,attr.source), vs)
        for vs in event_log.log_values]
    
    vocab = NLP.count_terms(values)
    normalized_values = NLP.normalize_by_max_count(values, vocab)
    
    if time_diff
        normalized_time = event_log.log_times / maximum(event_log.log_times)
        normalized_values = hcat(normalized_time, normalized_values)
    end

    normalized_values
end


#
# TOOD: persit log_keys
#
#   save and load global (key_id => log_keys)
#


# 
# Parsing utils
# 

function parse_rce_datetime(value::AbstractString)
    Dates.DateTime(value, dateformat"yyyy-mm-dd HH:MM:SS,sss")
end

function parse_syslog_datetime(value::AbstractString)
    try
        return Dates.DateTime(value, dateformat"u dd HH:MM:SS")
    catch
        return Dates.DateTime(value, dateformat"u  d HH:MM:SS")
    end
end

function parse_float(value::AbstractString, decimal::Char = '.')
    value = replace(value, Regex(string("[^\\d\\",decimal,"]")), "")
    value = replace(value, decimal, '.')
    parse(Float64, value)
end

function parse_comma_separated_float(value::AbstractString)
    parse_float(value, ',')
end

function parse_int(value::AbstractString)
    parse(Int64,value)
end


LineParser = OrderedDict{Symbol,Tuple{Label,Regex,Function}}(
    :rce_datetime    => (Label(:rce_datetime),    r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}", parse_rce_datetime),
    :syslog_datetime => (Label(:syslog_datetime), r"\b[A-Z][a-z]{2}\s{1,2}\d{1,2} \d{2}:\d{2}:\d{2}\b", parse_syslog_datetime),
    
    :file         => (Label(:file),    r"\b[\/\\]?([^\s]+)[\/\\]([^\/\s\.]+)\.[^\0]{2,4}\b", identity), # r"\b[^\/\.\s\0]+\.[^\0]{2,4}\b(?!\.)"
    :path         => (Label(:path),    r"\b[\/\\]?([^\s]+)[\/\\]([^\/\s\.]+)\b", identity),
    :uri          => (Label(:uri),     r"\b([a-zA-Z0-9]+[\:\/]{1,3})?(?=.*[\.])([\.\-\/\\]?[a-zA-Z0-9]+[\.\-\/\\])+[a-zA-Z0-9]{2,}?\b", identity),  

    :ipv4         => (Label(:ipv4),    r"\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b", identity),
    
    :float_simple => (Label(:float),   r"\b\d+[\.]\d+(?![\.])\b", parse_float),
    :float        => (Label(:float),   r"\b\d+([\,]\d+)?[\.]\d+(?![\.])\b", parse_float),
    
    
    :mac          => (Label(:mac),     r"\b(?:([0-9A-Fa-f]{2}[:-]){13}|([0-9A-Fa-f]{2}[:-]){5})([0-9A-Fa-f]{2})\b", identity),
    :ipv6         => (Label(:ipv6),    r"\b((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\b", identity),
    
    :hex_id       => (Label(:hex_id),  r"\b(:?(?=[a-fA-F]*?[0-9])(?=[0-9]*?[a-fA-F])(:?([0-9a-fA-F]+[\-\_\:]?)+[0-9a-fA-F]+))\b", identity), #(?!\.)
    :id           => (Label(:id),      r"\b(:?(?=[a-zA-Z]*?[0-9])(?=[0-9]*?[a-zA-Z])(:?([0-9a-zA-Z]+[\-\_\:]?)+[0-9a-zA-Z]+))\b", identity),
    # r"\b(:?(?=[a-zA-Z])(?=[a-zA-Z]*?[0-9])(:?([0-9a-zA-Z]+[\-\_\:]?)+[0-9a-zA-Z]+))\b(?!\%)"

    :version      => (Label(:version), r"\b(:?(\d{1,3})\.(\d{1,3})(\.\d{1,3})?([\_\-\+\.a-zA-Z0-9]+)?)\b", identity),
    :int          => (Label(:int),     r"(\b\d+|\d+\b)", parse_int), #(?!\%)
    :hex          => (Label(:hex),     r"\b0x[0-9A-Fa-f]+\b", identity),
    )

WordParser = OrderedDict{Symbol,Tuple{Label,Regex,Function}}(
    :hex_id       => (Label(:hex_id),  r"\b(:?(?=[a-fA-F]*?[0-9])(?=[0-9]*?[a-fA-F])(:?([0-9a-fA-F]+[\-\_\:]?)+[0-9a-fA-F]+))\b", identity), #(?!\.)
    :id           => (Label(:id),      r"\b(:?(?=[a-zA-Z])(?=[a-zA-Z]*?[0-9])(:?([0-9a-zA-Z]+[\-\_\:]?)+[0-9a-zA-Z]+))\b", identity), #(?!\%)
    :int          => (Label(:int),     r"(\b\d+|\d+\b)", parse_int), # (?!\%)
    :hex          => (Label(:hex),     r"\b0x[0-9A-Fa-f]+\b", identity),
    )

LineSplitter = OrderedDict{Symbol,Regex}(
    :rce_splitter           => r"\s+|[\.\,\=\:\@\$\(\)\[\]\{\}\\\/\'\"]+", # positive
    # :rce_splitter_negative  => r"\s+|[^a-zA-Z0-9\_\-\%\0]+",               # negative
)
