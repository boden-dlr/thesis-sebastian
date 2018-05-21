using Base.Test
using LogClustering.ETL

D = Dataset("*.log", "data/datasets/RCE/")
data = extract(D)[1:end]
es = transform(data)
DB = load(es)

N = length(data)

# do some useful queries on the Event-Logs

[length(filter(l-> l in [:ERROR], select(DB[i], :label))) for i in 1:N]

symbols = unique(vcat([select(DB[i], :label) for i in 1:N]...))

# [filter(c-> length(c) > 1, select(DB[i], :content)) for i in 1:1]
