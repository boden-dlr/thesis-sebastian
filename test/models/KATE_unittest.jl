using Base.Test
# using Flux: testmode!
using Flux.Tracker: data
using LogClustering.KATE
using LogClustering.KATE: KCompetetive

@testset "KCompetetive" begin

    @testset "Simplest KCompetetive Instance" begin
        l = KCompetetive(1, 2)
        @test size(l.W) == (2,1)
        @test length(l.b) == 2
        @test l.σ == tanh
    end

    @testset "Incorret parameter `k` for KCompetetive" begin
        @test_warn "k should not be larger than dim (out): 2, found (k): 3, using: 2" begin
            l = KCompetetive(1, 2, k=3)
            @test l.k == 2
        end
    end

    @testset "Example from the paper" begin

        # Example from the paper (version 2):
        #   "KATE: K-Competitive Autoencoder for Text"
        #   Yu Chen, Mohammed J. Zaki
        #   https://arxiv.org/abs/1705.02033v2
        # 
        # "Figure 1: Competitions among neurons. Input and hid-
        # den neurons, and hidden and output neurons are fully
        # connnected, but we omit these to avoid clutter."

        N = 10
        L = 6
        k = 2
        
        x = rand(N) # don't matter is ignored by zero weights
        @test length(x) == N
        
        z = [0.8, 0.2, 0.1, -0.1, -0.3, -0.6]
        @test z ≈ tanh.(atanh.(z))
        @test length(z) == L

        function activations(out)
            atanh.(z)
        end

        l = KCompetetive(N, L, tanh, initW=zeros, initb=activations, k=k)

        # mode: testing
        Flux.testmode!(l)
        @test l.active == false
        result = data(l(x))
        expected = z
        @test result ≈ expected

        # mode: training
        Flux.testmode!(l, false)
        @test l.active == true
        result = data(l(x))
        Epos = 0.3
        Eneg = -0.4
        expected = [0.8 + Epos * l.α, 0, 0, 0, 0, -0.6 + Eneg * l.α]
        @test result ≈ expected
    end
end
