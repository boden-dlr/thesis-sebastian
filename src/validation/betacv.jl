# using Clustering
using Distances
# using Flux: crossentropy

abstract type AbstractClustering end

struct Clustering{A,B} <: AbstractClustering
    k::Int64
    assignments::Dict{A,Array{B,1}}
end

function weights(S::AbstractArray, R::AbstractArray, metric::Function = Distances.euclidean)
    ws = 0.0
    for s in S
        for r in R
            ws += metric(s,r)
        end
    end
    ws
end

function weights_half(S::AbstractArray, R::AbstractArray, metric::Function = Distances.euclidean)
    ws = 0.0
    for (i,s) in enumerate(S)
        for (j,r) in enumerate(R)
            if i > j
                ws += metric(s,r)
            end
        end
    end
    ws
end

# https://www.coursera.org/learn/cluster-analysis/lecture/jDuBD/6-7-internal-measures-for-clustering-validation
function intra_cluster_weights(C::AbstractClustering)
    k = C.k
    assignments = collect(C.assignments)
    W_in = 0.0
    N_in = 0
    for (i,S) in assignments[1:k]
        W_in += weights_half(S,S)
        N_in += binomial(length(S),2)
    end
    W_in, N_in
end

function inter_cluster_weights(C::AbstractClustering)
    k = C.k
    assignments = collect(C.assignments)
    W_out = 0.0
    N_out = 0
    for (i,S) in assignments #[1:k-1]
        for (j,R) in assignments #[i+1:k]
            if j > i
                W_out += weights(S,R)
                N_out += length(S) * length(R)
            end
        end
    end
    W_out, N_out
end

function betacv(C::AbstractClustering)
    W_in, N_in = intra_cluster_weights(C)
    W_out, N_out = inter_cluster_weights(C)
    
    (W_in / N_in) / (W_out / N_out)
end
