module NeuralNets

    # LSTMs
    include("layers/Parallel.jl")
    include("layers/KATE.jl")
    include("layers/Sparse.jl")

    # activation functions
    include("activations.jl")

    # loss functions
    include("loss.jl")

end # module
