

function parse_event_log_two_stage(document::Vector{String};
    line_parser::Union{Vector{Tuple{Label,Regex,ParseFunction}},Nothing} = nothing,
    word_parser::Union{Vector{Tuple{Label,Regex,ParseFunction}},Nothing} = nothing,
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
                line = replace(line, label_chars => label_char_replacement)
                parsed_values = Vector{Pair{Int64,LogAttr}}()
                for (label, re, pf) in line_parser
                    values = matchall(re, line)
                    if any(v->contains(v, omit), values)
                        continue
                    end
                    for i in eachindex(values)
                        v = values[i]
                        push!(parsed_values, v.offset => LogAttr(
                            pf(v),
                            v,
                            label,
                            v.offset+1:v.offset+v.ncodeunits))
                    end
                    line = replace(line, re => label.label)
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
                                push!(parsed_values, pos+v.offset => LogAttr(
                                    pf(v),
                                    v,
                                    label,
                                    pos+v.offset+1:pos+v.offset+v.ncodeunits))
                            end
                            word = replace(word, re => label.label)
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
