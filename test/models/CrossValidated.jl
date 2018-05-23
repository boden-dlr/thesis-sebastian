using LogClustering.ETL
using LogClustering.Validation
using LogClustering.NLP
using LogClustering.KATE
using LogClustering.Clustering
using Flux
using Flux: throttle, crossentropy
using Clustering
using Distances
using DataStructures
using DataFrames
using CSV

D = Dataset("*.log", "data/datasets/RCE/")
raw = extract(D, take=4)

# corpus = map(doc -> map(line -> lowercase(line), doc), corpus)
splitby = r"\s+|[\.\,](?!\d)|[^\w\p{L}\-\_\.\,]"
corpus = map(doc -> map(line -> String.(split(line, splitby, keep=false)), doc), raw)

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

norm = transfrom(corpus)

function generate(doc::Normalized, seed::Integer)
    srand(seed)
    Xs = doc[1:end-1]
    Ys = doc[2:end]
    N = length(doc[1]) # normalized line (max line length)
    L = 2
    kc = 2
    m = Chain(
        KATE.KCompetetive(N, L, tanh, k=kc),
        Dense(L, N, sigmoid)
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
    embedded = hcat(Flux.data.(m[1].(doc))...)
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
    sd = sdbw(data, clustering)
    results["knn"] = (bcv,sd)

    results
end

function cross_validate()

# seed = 1234
seed = rand(1:10000)

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
        embedded = generate(vcat(cv.train), seed)
        train = cluster(embedded)
        # @show train

        info("cross-validation: test")
        embedded = generate(vcat(cv.test), seed)
        test = cluster(embedded)
        # @show test
        
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

df = cross_validate()
CSV.write(string("cross_validation.csv"), df)
for _ in 1:10
    df = cross_validate()
    CSV.write(string("cross_validation.csv"), df, append=true)
end
