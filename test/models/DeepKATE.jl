
using LogClustering.KATE
using LogClustering.Sequence: rows, cols
using Flux
using Flux: throttle, crossentropy

function fit_deep_kate(data::Vector{Vector{Float64}}, seed::Integer, n_components=3, epochs=1)
    srand(seed)
    Xs = data[1:end] # TODO/NOTE: no shift
    Ys = data[1:end]
    N = length(data[1]) # is normalized line (max line length)
    L = n_components
    # activate = sigmoid

    lat = 4

    m = Chain(
        KATE.KCompetetive(N, 100, tanh, k=25),
        # Dense(N, 100, sigmoid),
        Dense(100, 5, sigmoid),
        # KATE.KCompetetive(5, L, tanh, k=L), # round(Int,L/2)),
        Dropout(0.25),
        Dense(5, L, sin),
        # softmax,
        # softmax,
        Dense(L, 5, sigmoid),
        Dense(5, 100, sigmoid),
        Dense(100, N, sigmoid),
        # KATE.KCompetetive(N, L, tanh, k=25),
        # Dense(L, N, sigmoid),
    )

    function loss(a,b,c)
        # p,xs,n = triple(Xs)
        # @show length(a),length(b),length(c)
        
        target_a = m[1:lat](a)
        target_c = m[1:lat](c)

        embedded = m[1:lat](b)
        forward = m[lat+1:end](embedded)

        prev = Flux.mse(embedded, 1.0 .- target_a)
        succ = Flux.mse(embedded, 1.0 .- target_c)
        # @show "test"
        # prev = crossentropy(embedded, 1.0 .- target_a)
        # succ = crossentropy(embedded, 1.0 .- target_c)
        # prev = crossentropy(forward, 1.0 .- a)
        ce = crossentropy(forward, b)
        # succ = crossentropy(forward, 1.0 .- c)
        # @show prev
        # @show succ
        # @show ce
        # println()
        # Flux.truncate!(m)
        # 0.5*prev +
        prev + ce + succ
    end

    function callback()
        l = loss(Xs[4], Xs[5], Xs[6])
        println("loss:\t", l)
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
        info("Epoch $e")
        Flux.train!(
            loss,
            zip(Xs[1:end-2],Xs[2:end-1],Xs[3:end]),
            opt,
            cb = throttle(callback, 5))
    end

    for layer in m
        if layer isa KATE.KCompetetive
            layer.active = false
        end
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
