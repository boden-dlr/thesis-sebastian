using Base.Test
using LogClustering.Validation

# http://swl.htwsaar.de/lehre/ss17/ml/slides/2017-vl-ml-ch4-1-clustering.pdf
function naive_intra_cluster_weights(C::Clustering)
    as = collect(C.assignments)
    W_in = 0.0
    N_in = 0
    for (i,c) in as
        W_in += weights(c,c)
        N_in += length(c) * (length(c)-1)
    end
    0.5 * W_in, convert(Int64, 0.5 * N_in)
end

# http://swl.htwsaar.de/lehre/ss17/ml/slides/2017-vl-ml-ch4-1-clustering.pdf
function naive_inter_cluster_weights(C::Clustering)
    as = collect(C.assignments)
    W_out = 0.0
    N_out = 0
    for (i,S) in as
        for (j,R) in as
            if i != j
                W_out += weights(S,R)
                N_out += length(S) * length(R)
            end
        end
    end
    0.5 * W_out, convert(Int64, 0.5 * N_out)
end

# https://www.oursera.org/learn/cluster-analysis/lecture/jDuBD/6-7-internal-measures-for-clustering-validation
# This is wrong!
# function naive_n_out(C::Clustering)
#     as = collect(C.assignments)
#     N_out = 0
#     for (i, S) in as[1:C.k-1]
#         for (j, R) in as[i+1:end]
#             N_out += length(S) * length(R)
#         end
#     end
#     N_out
# end

# http://swl.htwsaar.de/lehre/ss17/ml/slides/2017-vl-ml-ch4-1-clustering.pdf
function naive_n_out(C::Clustering)
    as = collect(C.assignments)
    N_out = 0
    for (i, S) in as
        for (j, R) in as
            if i != j
                N_out += length(S) * length(R)
            end
        end
    end
    convert(Int64, 0.5 * N_out)
end



@testset "naive vs optimized" begin

    low_betacv = Dict(
        1 => [[1.0, 1.0], [1.1, 1.1]],
        2 => [[2.0, 2.0], [2.1, 2.1]],
        3 => [[3.0, 3.0], [3.1, 3.1]],
        4 => [[4.0, 4.0], [4.1, 4.1]],
        5 => [[5.0, 5.0], [5.1, 5.1]],
        6 => [[6.0, 6.0], [6.1, 6.1]],
    )

    C = Clustering(length(low_betacv), low_betacv)

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
    @test betacv(C) < (1.4681892332789561 / 10)

    high_betacv = Dict(
        1 => [[1.0, 1.0], [6.1, 6.1]],
        2 => [[2.0, 2.0], [5.1, 5.1]],
        3 => [[3.0, 3.0], [4.1, 4.1]],
        4 => [[4.0, 4.0], [3.1, 3.1]],
        5 => [[5.0, 5.0], [2.1, 2.1]],
        6 => [[6.0, 6.0], [1.1, 1.1]],
    )

    C = Clustering(length(high_betacv), high_betacv)

    @test betacv(C) > (0.0428571428571428 * 10)
    @test betacv(C) ≈ 1.4681892332789561

end
