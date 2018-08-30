using LogClustering.Parsing: parse_event_log_recursive
using LogClustering.Parsing: Label
using LogClustering.Parsing: parse_rce_datetime, parse_float, parse_int, Parser


text = readlines("data/datasets/RCE/2014-12-02_08-58-09_1048.log")
# text = readlines("data/datasets/RCE/2016-12-14_09-00-53_243818.log")

labels = [
    (Label("rce_datetime"), r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}", parse_rce_datetime),
    (Label("ipv4"), r"\d{3}\.\d{3}\.\d{3}\.\d{3}", identity),
    # (Label("german_float"), r"\d+\,\d+", parse_comma_separated_float),
    (Label("float"), r"\d+\.\d+", parse_float),
    #(Label("int"), r"(?:\b|\_)(\d+)(?=\b|\_)", parse_int),
    (Label("int"), r"\b\d+\b", parse_int),
]

labels = [
    Parser[:rce_datetime],
    Parser[:ipv4],
    Parser[:ipv6],
    Parser[:file],
    Parser[:path],
    Parser[:uri],
    Parser[:float],
    Parser[:hex_id],
    Parser[:id],
    Parser[:int],
    Parser[:hex],
]

splitter = r"\s+|[\.]"
splitter = r"\s+|[^\w\d]"

event_log = parse_event_log_recursive(text, labels, splitter)

event_log.log_keys
event_log.log_values
filter(!isempty,
    map(vals ->
        filter(v->v.label.label == "%ID%", vals),
        event_log.log_values))

event_log.log_times

using LogClustering.NLP

vocab = NLP.count_terms(event_log.log_keys)

labelnames = map(t->t[1].label, labels)
map(l-> haskey(vocab, l) ? l => vocab[l] : l => 0, labelnames)
