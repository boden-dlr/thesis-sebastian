
using LogClustering.KATE
using LogClustering.Sequence: rows, cols
using Flux
using Flux: throttle, crossentropy
using Random
using Statistics

include(joinpath(pwd(), "src/neural_nets/loss.jl"))

function fit_deep_kate(data::Vector{Vector{Float64}},
    seed::Integer,
    n_components=3,
    epochs=1,
    verbose=true)

    Random.seed!(seed)
    Xs = data[1:end]
    Ys = data[1:end]
    N = length(data[1]) # is normalized line (max line length)
    L = n_components
    # activate = sigmoid

    lat = 4

    m = Chain(
        # Dropout(0.2),
        KATE.KCompetetive(N, 100, tanh, k=25),
        # Dense(N, 100, sin),
        Dense(100, 20, sigmoid),
        # Dropout(0.2),
        # Dense(20, 5, sigmoid),
        KATE.KCompetetive(20, 20, tanh, k=10),
        # KATE.KCompetetive(5, L, tanh, k=L), # round(Int,L/2)),
        # Dense(20, 5, sigmoid),
        Dense(20, L, sin), # sin), #x->log(abs(x))
        # softmax,
        Dense(L, 20, sigmoid),
        Dense(20, 20, sigmoid),
        # Dropout(0.4),
        Dense(20, 100, sigmoid),
        Dropout(0.6),
        Dense(100, N, sigmoid),
        # KATE.KCompetetive(N, L, tanh, k=25),
        # Dense(L, N, sigmoid),
    )

    function loss(a,b,c)
        # @show length(a),length(b),length(c)

        # prepare latent targets
        cm = deepcopy(m)
        Flux.testmode!(m)
        target_a = Flux.data(cm[1:lat](a))
        target_c = Flux.data(cm[1:lat](c))

        # forward
        embedded = m[1:lat](b)
        prediction = m[lat+1:end](embedded)

        prev = Flux.mse(embedded, -target_a) # repel! (see neural_nets/loss.jl)
        succ = Flux.mse(embedded, -target_c) # repel!
        ce = crossentropy(prediction, b)
        # ce = Flux.mse(prediction, b)

        # @show prev, ce, succ
        prev + ce + succ
    end

    function callback()
        if verbose
            l = loss(Xs[4], Xs[5], Xs[6])
            println("loss:\t", l)
        end
    end

    opt = Flux.ADAM(params(m))

    # function triple(v)
    #     n = length(v)
    #     M = Matrix(n-2,3)
    #     for i in 1:n-2
    #         for j in 1:3
    #             M[i,j] = v[i+j-1]
    #         end
    #     end
    #     M
    # end

    for e = 1:epochs
        if verbose
            @info "Epoch $e"
        end
        Flux.train!(
            loss,
            zip(Xs[1:end-2],Xs[2:end-1],Xs[3:end]),
            opt,
            cb = throttle(callback, 5))
    end

    Flux.testmode!(m)
    m
end

function generate(model::Flux.Chain, data::Vector{Vector{Float64}})
    embeddings = hcat(Flux.data.(model[1:4].(data))...)
    generated = hcat(Flux.data.(model.(data))...)
    embeddings', generated'
end

# determine outliers
function reconstruction_error(in::AbstractMatrix,out::AbstractMatrix)
    # reconstruction_error_se = [sum(line) for line in rows((normalized_matrix .- generated').^2)]
    reconstruction_errors = [sum(line) for line in rows(abs.(in .- out))]

    std_error = Statistics.std(reconstruction_errors)
    median_error = Statistics.median(reconstruction_errors)
    mean_error = Statistics.mean(reconstruction_errors)

    (reconstruction_errors, std_error, median_error, mean_error)
end


function scale(data::AbstractMatrix, factor=10.0, shift_to_origin=true, scale_by=:max)
    data = data'
    (n,m) = size(data)
    if scale_by == :max
        min_embd = [minimum(data[i,:]) for i in 1:n]
        max_embd = [maximum(data[i,:]) for i in 1:n]
    else
        min_embd = [Statistics.quantile(data[i,:], 0.2) for i in 1:n]
        max_embd = [Statistics.quantile(data[i,:], 0.8) for i in 1:n]
    end
    med = [Statistics.quantile(data[i,:], 0.5) for i in 1:n]
    if shift_to_origin
        diff_embd = factor*2.0 ./ (max_embd - min_embd)
    else
        diff_embd = factor ./ (max_embd - min_embd)
    end

    strech = zeros(n,n)
    for i in 1:n
        strech[i,i] = diff_embd[i]
    end

    if shift_to_origin
        if scale_by == :max
            data = strech * (data .- min_embd) .- factor
        else
            data = (strech * (data .- min_embd)) .- med
        end
    else
        data = (strech * (data .- min_embd))
    end
    data = data'
end
