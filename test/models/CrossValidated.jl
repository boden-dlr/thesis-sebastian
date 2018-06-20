using LogClustering.ETL
using LogClustering.Validation
using LogClustering.NLP
using LogClustering.KATE
using LogClustering.ClusteringUtils
using Flux
using Flux: throttle, crossentropy
using Clustering
using Distances
using DataStructures
using DataFrames
using Base.Dates
using CSV

Normalized = Array{Array{Float64,1},1}

function transfrom(corpus::NLP.Corpus)
    data = Vector{Normalized}()
    for doc in corpus
        terms = NLP.terms(doc)
        count = NLP.count_terms(doc, terms=terms)
        norm = KATE.normalize(doc, count)
        push!(data,norm)
    end
    data
end


function train_model(doc::Normalized, seed::Integer)
    srand(seed)
    Xs = doc[1:end-1]
    Ys = doc[2:end]
    N = length(doc[1]) # normalized line (max line length)
    L = 2
    activate = sin
    m = Chain(
        KATE.KCompetetive(N, 100, tanh, k=25),
        Dense(100, 5, activate),
        KATE.KCompetetive(5, L, tanh, k=L),
        Dense(L, 5, activate),
        Dense(5, 100, activate),
        Dense(100, N, sigmoid)
    )
    function loss(xs, ys)
        crossentropy(m(xs), ys)
    end
    function callback()
        l = loss(Xs[5], Ys[5])
        println("loss:\t", l)
    end
    opt = Flux.ADAM(params(m))
    for e = 1:1
        info("Epoch $e")
        Flux.train!(
            loss,
            zip(Xs, Ys),
            opt,
            cb = throttle(callback, 5))
    end
    Flux.testmode!(m)
    m[1].active = false
    m
end

function cluster(data::Matrix{Float64})
    results = DataStructures.OrderedDict{String,Tuple{Float64,Float64}}()

    dbc = Clustering.dbscan(data, 0.001)
    clustering = map(c->vcat(c.core_indices, c.boundary_indices), dbc)
    # @show length(clustering), typeof(clustering)
    values = map(c->data[:,c],clustering)
    bcv = betacv_pairwise(values)
    sd = sdbw(data, clustering)
    results["dbscan"] = (bcv,sd)

    clustering, _ = knn_clustering(data)
    # @show length(clustering), typeof(clustering)
    values = map(c->data[:,c],clustering)
    bcv = betacv_pairwise(values)
    sd = sdbw(data, clustering, dense=false)
    results["knn"] = (bcv,sd)

    results
end


function cross_validate(norm::Array{Normalized,1}, seed::Int64 = rand(1:10000))

df = DataFrame(
    seed=Int64[],
    doc=Int64[], 
    round=Int64[], 
    k=Int64[], 
    train_dbscan_betacv=Float64[], 
    train_dbscan_sdbw=Float64[],
    train_knn_betacv=Float64[], 
    train_knn_sdbw=Float64[],
    test_dbscan_betacv=Float64[], 
    test_dbscan_sdbw=Float64[],
    test_knn_betacv=Float64[], 
    test_knn_sdbw=Float64[])

for (i,doc) in enumerate(norm)
for cv in k_fold_out_of_time(doc)
    info("cross-validation: ", cv.i, "/", cv.k, "; document ($i); seed ($seed)")
    info("cross-validation: train")
    data = vcat(cv.train)
    @show length(data), typeof(data)
    model = train_model(data, seed)
    embedded = hcat(Flux.data.(model[1].(data))...)
    train = cluster(embedded)

    info("cross-validation: test")
    data = cv.test
    @show length(data), typeof(data)
    embedded = hcat(Flux.data.(model[1].(data))...)
    test = cluster(embedded)
    
    vs = [seed, i, cv.i, cv.k, vcat(
        train["dbscan"]...,
        train["knn"]...,
        test["dbscan"]...,
        test["knn"]...)...]
    @show vs
    push!(df, vs)
    
    println()
end
    println("-------------------------------------")
end

df
end


D = Dataset("*.log", "data/datasets/RCE/")
raw = extract(D, take=3)
# corpus = map(doc -> map(line -> lowercase(line), doc), corpus)
splitby = r"\s+|[\.\,](?!\d)|[^\w\p{L}\-\_\.\,]"
corpus = map(doc -> map(line -> String.(split(line, splitby, keep=false)), doc), raw)
normalized = transfrom(corpus)

id = Dates.format(now(), dateformat"Y-mm-dd_HHMMSS")
filename = "data/clustering/cross_validation_$id.csv"

df = cross_validate(normalized)
CSV.write(filename, df)
for _ in 1:9
    df = cross_validate(normalized)
    CSV.write(filename, df, append=true)
end
