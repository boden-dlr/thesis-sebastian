
using LogClustering.KATE
using LogClustering.Sequence: rows, cols
using Flux
using Flux: throttle, crossentropy

function fit_deep_kate(data::Vector{Vector{Float64}}, seed::Integer, n_components=3, epochs=1)
    srand(seed)
    Xs = data[1:end-1]
    Ys = data[2:end]
    N = length(data[1]) # is normalized line (max line length)
    L = n_components
    activate = sin

    m = Chain(
        KATE.KCompetetive(N, 100, tanh, k=25),
        Dense(100, 5, activate),
        KATE.KCompetetive(5, L, tanh, k=L),
        Dense(L, 5, activate),
        Dense(5, 100, activate),
        Dense(100, N, sigmoid)
        # KATE.KCompetetive(N, L, tanh, k=25),
        # Dense(L, N, sigmoid)
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

    for e = 1:epochs
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

function generate(model::Flux.Chain, data::Vector{Vector{Float64}})
    embeddings = hcat(Flux.data.(model[1:3].(data))...)
    generated = hcat(Flux.data.(model.(data))...)
    embeddings', generated'
end

# determine outliers
function reconstruction_error(in::AbstractMatrix,out::AbstractMatrix)
    # reconstruction_error_se = [sum(line) for line in rows((normalized_matrix .- generated').^2)]
    reconstruction_errors = [sum(line) for line in rows(abs.(in .- out))]

    std_error = std(reconstruction_errors)
    median_error = median(reconstruction_errors)
    mean_error = mean(reconstruction_errors)

    (reconstruction_errors, std_error, median_error, mean_error)
end


function scale(data::AbstractMatrix, factor=10.0, shift_to_origin=true)
    data = data'
    (n,m) = size(data)
    min_embd = [minimum(data[i,:]) for i in 1:n]
    max_embd = [maximum(data[i,:]) for i in 1:n]
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
        data = strech * (data .- min_embd) - factor
    else
        data = strech * (data .- min_embd) - factor
    end
    data = data'
end
