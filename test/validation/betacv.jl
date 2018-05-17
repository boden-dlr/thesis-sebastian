using Base.Test
using LogClustering.Validation

# http://swl.htwsaar.de/lehre/ss17/ml/slides/2017-vl-ml-ch4-1-clustering.pdf
function naive_intra_cluster_weights(C::AbstractArray)
    W_in = 0.0
    N_in = 0
    for (i,c) in enumerate(C)
        W_in += weights(c,c)
        N_in += length(c) * (length(c)-1)
    end
    0.5 * W_in, convert(Int64, 0.5 * N_in)
end

# http://swl.htwsaar.de/lehre/ss17/ml/slides/2017-vl-ml-ch4-1-clustering.pdf
function naive_n_in(C::AbstractArray)
    N_in = 0
    for (i,c) in enumerate(C)
        N_in += length(c) * (length(c)-1)
    end
    convert(Int64, 0.5 * N_in)
end

# http://swl.htwsaar.de/lehre/ss17/ml/slides/2017-vl-ml-ch4-1-clustering.pdf
function naive_inter_cluster_weights(C::AbstractArray)
    W_out = 0.0
    N_out = 0
    for (i,S) in enumerate(C)
        for (j,R) in enumerate(C)
            if i != j
                W_out += weights(S,R)
                N_out += length(S) * length(R)
            end
        end
    end
    0.5 * W_out, convert(Int64, 0.5 * N_out)
end

# http://swl.htwsaar.de/lehre/ss17/ml/slides/2017-vl-ml-ch4-1-clustering.pdf
function naive_n_out(C::AbstractArray)
    N_out = 0
    for (i, S) in enumerate(C)
        for (j, R) in enumerate(C)
            if i != j
                N_out += length(S) * length(R)
            end
        end
    end
    convert(Int64, 0.5 * N_out)
end


@testset "naive vs optimized" begin

    # using Clustering
    # low_betacv = [
    #     1.0  1.1  2.0  2.1  3.0  3.1  4.0  4.1  5.0  5.1  6.0  6.1;
    #     1.0  1.1  2.0  2.1  3.0  3.1  4.0  4.1  5.0  5.1  6.0  6.1;
    # ]
    # DM = pairwise(Euclidean(), low, low)
    # C = dbscan(DM, 0.15, 2)
    # ... view(data assignments)

    # low BetaCV
    C = [
        [[1.0, 1.0], [1.1, 1.1]], # 1
        [[2.0, 2.0], [2.1, 2.1]], # 2
        [[3.0, 3.0], [3.1, 3.1]], # 3
        [[4.0, 4.0], [4.1, 4.1]], # 4
        [[5.0, 5.0], [5.1, 5.1]], # 5
        [[6.0, 6.0], [6.1, 6.1]], # 6
    ]

    # intra
    expected = naive_intra_cluster_weights(C)
    result   = intra_cluster_weights(C)
    @test expected[1] ≈ result[1]
    @test expected[2] ≈ result[2]
    @test naive_n_in(C) == 6
    @test naive_n_in(C) == result[2]
    
    # inter
    expected = naive_inter_cluster_weights(C)    
    result   = inter_cluster_weights(C)
    @test expected[1] ≈ result[1]
    @test expected[2] ≈ result[2]
    @test naive_n_out(C) == 60
    @test naive_n_out(C) == result[2]

    @test betacv(C) ≈ 0.0428571428571428
    @test betacv(C) < (1.4681892332789561 / 10)

    # high BetaCV
    C = [
        [[1.0, 1.0], [6.1, 6.1]], # 1
        [[2.0, 2.0], [5.1, 5.1]], # 2
        [[3.0, 3.0], [4.1, 4.1]], # 3
        [[4.0, 4.0], [3.1, 3.1]], # 4
        [[5.0, 5.0], [2.1, 2.1]], # 5
        [[6.0, 6.0], [1.1, 1.1]], # 6
    ]

    @test betacv(C) > (0.0428571428571428 * 10)
    @test betacv(C) ≈ 1.4681892332789561

end


@testset "Flux.Tracker: betacv (tracked)" begin
    using Flux.Tracker

    C = [
        [param([1.0, 1.0]), param([1.1, 1.1])], # 1
        [param([2.0, 2.0]), param([2.1, 2.1])], # 2
        [param([3.0, 3.0]), param([3.1, 3.1])], # 3
        [param([4.0, 4.0]), param([4.1, 4.1])], # 4
        [param([5.0, 5.0]), param([5.1, 5.1])], # 5
        [param([6.0, 6.0]), param([6.1, 6.1])], # 6
    ]

    # intra
    expected = naive_intra_cluster_weights(C)
    result   = intra_cluster_weights(C)
    @test expected[1] ≈ result[1]
    @test expected[2] ≈ result[2]
    
    # inter
    expected = naive_inter_cluster_weights(C)
    result   = inter_cluster_weights(C)
    @test expected[1] ≈ result[1]
    @test expected[2] ≈ result[2]
    @test naive_n_out(C) == 60
    @test naive_n_out(C) == result[2]

    @test betacv(C) ≈ 0.0428571428571428

    C[1][1].grad ≈ [0.0, 0.0]

    back!(betacv(C))

    @test C[1][1].grad[1] ≈ -0.034183673469387735
    @test C[1][1].grad[2] ≈ -0.034183673469387735

end

# @testset "Deep-Autoencoder with Crossentropy and BetaCV loss" begin
using Flux
using Flux.Tracker
using Flux: softmax, relu, leakyrelu, mse, crossentropy, throttle
using Flux: normalise
using LogClustering.Clustering: knn_clustering
using LogClustering.Validation: betacv

function train(seed::Int)
    srand(seed)

    N = 10000   # samples
    M = 100     # data size
    L = 2       # latent space

    D = map(_->rand(M),1:N)
    X = deepcopy(D[1:end-1])
    Y = deepcopy(D[2:end])

    a = tanh
    m = Chain(
        Dense(M,   100, a),
        Dense(100, 10,  a),
        Dense(10,  L,   a),
        Dense(L,   10,  a),
        Dense(10,  100, a),
        Dense(100, M,   sigmoid),
    )
    el = 3

    function supervised_betacv()
        # Embed all samples from X into the latent space of size L
        embds_tracked = map(x-> m[1:el](x), X)
        embds  = hcat(map(ta->ta.data, embds_tracked)...)
        
        # Cluster the current embeddings without tracking to generate
        # a supervised scenario.
        # This clould also be done by DBSCAN, OPTICS, K-Means ...
        clustering, _ = knn_clustering(embds)

        # Obtain tracked embedded values from the clustering
        values_tracked = map(c->map(i->embds_tracked[i],c), clustering)

        # Validate the clustering via BetaCV measure (small is good).
        # This is done the tracked values, as it should influence
        # the model weights and biases towards optimizing this measure.
        bcv = betacv(values_tracked)

        bcv
    end

    function loss(x, y)
        # unsupervised
        ŷ = m(x)
        ce = crossentropy(ŷ, y)

        # supervised
        bcv = 0.0
        if false # apply after a certain amount of training
            bcv = supervised_betacv()
        end

        # optimize both metrics
        ce + bcv
    end

    opt = Flux.ADAM(params(m))

    function callback()
        ns = rand(1:N-1, round(Int, sqrt(N)))
        ls = map(n->loss(X[n], Y[n]).tracker.data, ns)
        println("Training:  loss: ", sum(ls), "\tstd: ", std(ls))

        # embeddings
        es = m[1:el](X[rand(1:N-1)]).data
        println("Embedding: ", es)
        println()
    end

    for epoch in 1:1
        info("Epoch: $epoch ($seed)")
        Flux.train!(loss, zip(X, Y), opt, cb=throttle(callback,3))
    end
end

train(rand(1:10000))
# end