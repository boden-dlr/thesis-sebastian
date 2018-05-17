using Clustering
using Distances

# M. Halkidi and M. Vazirgiannis: Clustering Validity Assessment: Finding
# the Optimal Partitioning of a Data Set, Proc. of ICDM 2001, pp. 187-194,
# 2001

# Scat Dense bw

# D         dataset
# d         number of dimensions
# n         number of objects in D
# c         center of D
# P         attributes number of D 
# nc        number of clusters
# C[i]      i-th cluster
# n_i       number of object in C[i]
# c_i       center of C[i]
# std       variance vector of C[i]
# d(x,y)    distance between x and y
# ||X_i|| = (X_i' * X_i)^1/2

# function variance_dataset(X::AbstractArray)
#     d,n = size(D)
#     vs = zeros(d)
#     for p in 1:d
#         vs[p] = var(X[p,:], corrected=false)
#     end
#     vs
# end

function variance(X::AbstractArray, mean::AbstractArray)
    d,n = size(X)
    vs = zeros(d)
    for i in 1:n
        vs += (X[:,i].-mean).^2
    end
    vs ./ n
end

function sqrt_norm(xs)
    sqrt(xs'*xs)
end

function medoid(C_i::AbstractArray)
    cost = Distances.pairwise(Euclidean(), C_i, C_i)
    mr = Clustering.kmedoids(cost,1)
    medoid_idx = mr.medoids[1]
    C_i[:,medoid_idx]
end

function scattering(D::AbstractArray, C::AbstractArray)
    d,n = size(D)
    nc = length(C)
    stdD = sqrt_norm(variance(D, [mean(D[p,:]) for p in 1:d]))
    scat = 0.0
    for i in 1:nc
        scat += sqrt_norm(variance(C[i], medoid(C[i]))) / stdD
    end
    scat / n
end

function avg_std(C::AbstractArray)
    nc = length(C)
    std = 0.0
    for i in nc
        std += sqrt_norm(variance(C[i], medoid(C[i])))
    end
    sqrt(std) / nc
end


function density(X::AbstractArray, point::AbstractArray, radius::Float64)
    cost = abs.(Distances.colwise(Euclidean(), X, point))
    count = 0
    for c in cost
        # hyper-sphere around `point` with radius `radius`
        if c <= radius
            count += 1
        end
    end
    count
end

function dense_bw(C::AbstractArray)
    nc = length(C)
    stdC = avg_std(C)
    sum = 0.0
    for i in 1:nc
        for j in 1:nc
            if i != j
                v_i  = medoid(C[i]) 
                v_j  = medoid(C[j])
                from = min.(v_i,v_j)
                u_ij = from .+ (0.5 .* Distances.euclidean.(v_i, v_j))
                
                # NOTE: maybe for the whole dataset?! `D` instead of `C[i]`?
                d_v_i  = density(C[i], v_i,  stdC)
                d_v_j  = density(C[i], v_j,  stdC)
                d_u_ij = density(C[i], u_ij, stdC)

                sum += d_u_ij / max(d_v_i, d_v_j)
            end
        end
    end
    sum / nc*(nc-1)
end

function sdbw(D::AbstractArray, C::AbstractArray)
    scattering(D,C) + dense_bw(C)
end
