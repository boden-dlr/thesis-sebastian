using Base.Test
using LogClustering.ETL

D = Dataset("*.log", "data/datasets/RCE/")
data = extract(D)[1:5]
es = transform(data)
DB = load(es)

N = length(data)

# do some useful queries on the Event-Logs

errors = [length(filter(l-> l in [:ERROR], select(DB[i], :label))) for i in 1:N]

unique_labels = unique(vcat([select(DB[i], :label) for i in 1:N]...))

# [filter(c-> length(c) > 1, select(DB[i], :content)) for i in 1:1]

filter(p-> p.label in [:ERROR], select(DB[5], (:id,:label,:range)))

pipe = filter(r->r.label == :ERROR, DB[5])
pipe = map(r->(r.id,r.range,r.range[2]-r.range[1]+1), pipe)


pipe = filter(p-> p.label in [:ERROR], select(DB[5], (:id,:timestamp,:label,:content,:range)))
pipe = map(event->string(event.content...), pipe)
pipe = map(lines->replace(lines, r"\d+[\.\,](?!\d)\d+","%float%"), pipe)
pipe = map(lines->replace(lines, r"\d+", "%integer%"), pipe)
pipe = map(lines->split(lines, r"\s+|[^\w\p{L}\_]", keep=false), pipe)

pipe = length(filter(event->any(contains(line, "%integer%") for line in event), pipe))


