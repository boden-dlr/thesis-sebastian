using Base.Test
using LogClustering.Validation

D = [
    -1.0 -1.1 -1.2 -1.3 -1.4 2.0 2.1 2.2;
    -1.0 -1.1 -1.2 -1.3 -1.4 2.0 2.1 2.2;
]

C = [
    [-1.0 -1.1 -1.2 -1.3 -1.4;
     -1.0 -1.1 -1.2 -1.3 -1.4],
    [2.0 2.1 2.2;
     2.0 2.1 2.2],
]

@testset "S_Dbw utils" begin

    m = medoid(C[1])

    c_var = variance(C[1], medoid(C[1]))

    function time(f)
        t = @timed f
        t[2]
    end

    # @time variance_dataset(D)
    # sum(map(_->time(variance_dataset(D)),1:100000))

    varD = @time variance(D, [mean(D[1,:]),mean(D[2,:])])
    sum(map(_->time(variance(D, [mean(D[1,:]),mean(D[2,:])])),1:100000))

    stdC = avg_std(C)

    density(C[1],medoid(C[1]),stdC)
    density(D,medoid(C[1]),stdC)

    @test scattering(D,C) ≈ 0.0012983587933377966
    @test dense_bw(C) == 0

end

@testset "S_Dbw" begin

    @test sdbw(D,C) ≈ 0.0012983587933377966
    @test sdbw(D,C) == scattering(D,C)

end