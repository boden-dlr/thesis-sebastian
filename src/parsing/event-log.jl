using LogClustering.NLP
using LogClustering.Parsing: Label, LogAttr, EventLog


function normalize_log_keys(event_log::EventLog; padding = 250)
    vocab = NLP.count_terms(event_log.log_keys)
    data = NLP.normalize_by_max_count(event_log.log_keys, vocab, max_length = padding)

    lkl = map(length, event_log.log_keys)
    max = maximum(lkl)
    s = lkl ./ max
    # hcat(s, data .* s, s)

    # data
    # hcat(s, data .* s, s)
    hcat(s, data)
end


function normalize_log_values(event_log::EventLog; padding = 250, time_diff=true)
    values = Vector{String}[
        map(attr -> convert(String,attr.source), vs)
        for vs in event_log.log_values]

    vocab = NLP.count_terms(values)
    normalized_values = NLP.normalize_by_max_count(values, vocab, max_length = padding)

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
