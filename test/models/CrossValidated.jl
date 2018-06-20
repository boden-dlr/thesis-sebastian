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
using Base.Iterators
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
        ce = crossentropy(m(xs), ys)
        Flux.truncate!(m)
        ce
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
    m[3].active = false
    m
end


function cluster(data::Matrix{Float64})
    results = DataStructures.OrderedDict{String,Tuple{Int64, Float64,Float64}}()

    for (i, eps) in enumerate([1e-2, 1e-3, 1e-4])
        dbc = Clustering.dbscan(data, eps)
        clustering = map(c->vcat(c.core_indices, c.boundary_indices), dbc)
        cn = length(clustering)
        # @show length(clustering), typeof(clustering)
        values = map(c->data[:,c],clustering)
        bcv = betacv_pairwise(values)
        sd = sdbw(data, clustering)
        results["dbscan_$i"] = (cn,bcv,sd)
    end

    clustering, _ = knn_clustering(data)
    # @show length(clustering), typeof(clustering)
    values = map(c->data[:,c],clustering)
    cn = length(clustering)
    bcv = betacv_pairwise(values)
    # sd = sdbw(data, clustering)
    sd = sdbw(data, clustering, dense=false) # only scattering
    results["knn"] = (cn,bcv,sd)

    results
end


function cross_validate(norm::Array{Normalized,1}, seed::Int64 = rand(1:10000))

    df = DataFrame(
        seed=Int64[],
        doc=Int64[], 
        lines=Int64[], 
        round=Int64[], 
        k=Int64[],
        train=Int64[],
        test=Int64[],
        train_dbscan1_n=Int64[],
        train_dbscan1_betacv=Float64[], 
        train_dbscan1_sdbw=Float64[],
        train_dbscan2_n=Int64[],
        train_dbscan2_betacv=Float64[], 
        train_dbscan2_sdbw=Float64[],
        train_dbscan3_n=Int64[],
        train_dbscan3_betacv=Float64[], 
        train_dbscan3_sdbw=Float64[],
        train_knn_n=Int64[],
        train_knn_betacv=Float64[], 
        train_knn_sdbw=Float64[],
        test_dbscan1_n=Int64[],
        test_dbscan1_betacv=Float64[], 
        test_dbscan1_sdbw=Float64[],
        test_dbscan2_n=Int64[],
        test_dbscan2_betacv=Float64[], 
        test_dbscan2_sdbw=Float64[],
        test_dbscan3_n=Int64[],
        test_dbscan3_betacv=Float64[], 
        test_dbscan3_sdbw=Float64[],
        test_knn_n=Int64[],
        test_knn_betacv=Float64[], 
        test_knn_sdbw=Float64[])

    N_docs = length(norm)

    for (i,doc) in enumerate(norm)
        lines = length(doc)
        for cv in k_fold_out_of_time(doc)
            data = vcat(cv.train)
            # @show length(data), typeof(data)
            train_n = length(data)
            info("cross-validation: ", cv.i, "/", cv.k, "; document: $i/$N_docs; data: $lines; seed: $seed")
            info("cross-validation: train: $train_n")
            model = train_model(data, seed)
            embedded = hcat(Flux.data.(model[1].(data))...)
            train = cluster(embedded)

            data = cv.test
            # @show length(data), typeof(data)
            test_n = length(data)
            info("cross-validation: test: $test_n")
            embedded = hcat(Flux.data.(model[1].(data))...)
            test = cluster(embedded)
            
            vs = [seed, i, lines, cv.i, cv.k, train_n, test_n, collect(
                Iterators.flatten(
                    Iterators.flatten(vcat(values(train), values(test)))))...]
            @show vs
            push!(df, vs)
            
            println()
        end
        println("-------------------------------------")
    end

    df
end


D = Dataset("*.log", "data/datasets/RCE/")
# raw = extract(D, take=3)
raw = extract(D, take=1, randomize=true)
# corpus = map(doc -> map(line -> lowercase(line), doc), corpus)
# splitby = r"\s+|[\.\,](?!\d)|[^\w\p{L}\-\_\.\,]"
splitby = r"\s+"
corpus = map(doc -> map(line -> String.(split(line, splitby, keep=false)), doc), raw)
normalized = transfrom(corpus)

id = Dates.format(now(), dateformat"Y-mm-dd_HHMMSS")
filename = "data/clustering/cross_validation_$id.csv"

df = cross_validate(normalized)
CSV.write(filename, df)
for _ in 1:4 # total: 1+4
    df = cross_validate(normalized)
    CSV.write(filename, df, append=true)
end
