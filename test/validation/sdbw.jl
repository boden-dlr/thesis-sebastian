using Test
using LogClustering.Validation
using Statistics

D = [
    -1.0 -1.1 -1.2 -1.3 -1.4 2.0 2.1 2.2;
    -1.0 -1.1 -1.2 -1.3 -1.4 2.0 2.1 2.2;
]

C = [
    [1,2,3,4,5],
    [6,7,8],
]

DC = [view(D,:,c) for c in C]

@testset "S_Dbw utils" begin

    m = medoid(DC[1])
    @test m == [-1.2,-1.2]

    c_var = variance(DC[1], m)
    @test c_var ≈ [0.02,0.02]

    function time(f)
        t = @timed f
        t[2]
    end

    # @time variance_dataset(D)
    # sum(map(_->time(variance_dataset(D)),1:100000))

    varD = @time variance(D, [mean(D[1,:]),mean(D[2,:])])
    # sum(map(_->time(variance(D, [mean(D[1,:]),mean(D[2,:])])),1:100000))

    stdC = avg_std(DC)

    density(DC[1],m,stdC)
    density(D,m,stdC)

    @test scattering(D,C,DC) ≈ 0.0012983587933377966
    @test dense_bw(D,C,DC) == 0

end

@testset "S_Dbw" begin

    sdbw_r, scat_r, dbw_r = sdbw(D,C)
    @test sdbw_r ≈ 0.0012983587933377966

    sdbw_r, scat_r, dbw_r = sdbw(D,C)
    @test sdbw_r == scattering(D,C,DC)

end
