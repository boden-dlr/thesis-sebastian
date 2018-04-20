
filename = "/home/sebastian/develop/topic/clustering/LogClustering.jl/data/logs/2018-03-01_15-11-18_51750.log"

data = readlines(filename)

template = r"^(\d{4,4}\-\d{2,2}\-\d{2,2}\ \d{2,2}\:\d{2,2}\:\d{2,2}\,\d{3,3}) ([A-Z]+)(.*)"

m = match(template, data[1])
# filter(s->length(s) != 0, split(m[3], " - "))

eventlog = [Array{String,1}()]
payloads = [Array{String,1}()]
payload = Array{String,1}()
for line in data
    m = match(template, line)
    if typeof(m) != Void
        # add optional payload from previous event
        push!(payloads, payload)
        payload = Array{String,1}()
        # infer this event
        attributes::Array{String} = [m[1], m[2], filter(s->length(s) != 0, split(m[3], " - "))...]
        push!(eventlog, attributes)
    else
        push!(payload, line)
    end
end

eventlog

attributes_count = map(e -> length(e), eventlog)
maximum(attributes_count)
collect(enumerate(attributes_count))
eventlog[8]

maximum(map(p -> length(p), payloads))
length(filter(p -> length(p) == 28, payloads))
length(filter(p -> length(p) > 0, payloads))
