using BSON: @save
using LogClustering.Parsing
using LogClustering.Parsing: EventLog
using LogClustering.NLP
using DataStructures: OrderedDict

mutable struct LogCorpus
    log_keys::OrderedDict{Vector{String},Int64}
    embeddings::Vector{Vector{Float64}}
    event_logs::Vector{EventLog}
    filenames::Vector{String}

    LogCorpus() = new(
        OrderedDict{Vector{String},Int64}(),
        Vector{Vector{Float64}}(),
        Vector{EventLog}(),
        Vector{String}(),
    )
end

function get_id(values, value)
    findfirst(v->v==value, values)
end

function add_event_log!(db::LogCorpus, event_log::EventLog, filename::String)
    id = get_id(db.filenames, filename)
    if id == 0 || id == nothing
        push!(db.event_logs, event_log)
    else
        db.event_logs[id] = event_log
    end

    lks = unique(lk for el in db.event_logs for lk in el.log_keys)
    for lk in lks
        if !haskey(db.log_keys, lk)
            db.log_keys[lk] = length(db.log_keys)+1
        end
    end
end


# 
# tests
# 

using Glob

log_files = Glob.glob("data/datasets/RCE/*.log")

db = LogCorpus()
for filename = log_files[5:5]
    info("file: $filename")
    log = readlines(filename)

    lp = Tuple{Label,Regex,Function}[
        Parsing.LineParser[:rce_datetime],
        Parsing.LineParser[:file],
        Parsing.LineParser[:path],
        Parsing.LineParser[:uri],
        Parsing.LineParser[:ipv4],
        Parsing.LineParser[:float],
        Parsing.LineParser[:mac],
        # Parsing.LineParser[:ipv6],
        Parsing.LineParser[:version],
        Parsing.LineParser[:hex_id],
        Parsing.LineParser[:id],
        Parsing.LineParser[:int],
        ]

    wp = Tuple{Label,Regex,Function}[
        # Parsing.WordParser[:uri],
        # Parsing.WordParser[:path],
        Parsing.WordParser[:hex_id],
        Parsing.WordParser[:id],
        Parsing.WordParser[:int],
        ]

    event_log = @time Parsing.parse_event_log(log,
        line_parser = lp,
        # word_parser = wp,
        line_splitter = Parsing.LineSplitter[:rce_splitter])

    # NLP.count_terms(event_log.log_keys)

    add_event_log!(db, event_log, filename)
end


file = open("data/preprocessed/log_keys.log", "w")
for key in keys(db.log_keys)
    write(file, key)
    write(file, "\n")
end
close(file)

# log_keys = db.log_keys
# @save "data/preprocessed/log_keys.bson" log_keys

db.log_keys