module NeuralNet

    # LSTMs
    include("layers/Parallel.jl")

    # activation functions
    include("activations.jl")

    # loss functions
    include("loss.jl")

end # module
