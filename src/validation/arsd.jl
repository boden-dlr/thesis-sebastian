using Distances


"""
maximum diameter (md)
"""
function md(cluster)
    maximum(pairwise(Euclidean(), cluster))
end

"""
standard deviation-based compactness measure CM_SD
"""
function cm_sd(data::AbstractMatrix, clustering::Vector{Vector{Int}})
    cms = zeros(length(clustering))
    for i in eachindex(clustering)
        cluster = clustering[i]
        if length(cluster) > 1
            points = @views data[cluster, :]'
            md_k  = md(points)
            if md_k > 0.0
                sd_k = std(points)
                cms[i] = (md_k - sd_k) / md_k
            end
        end
    end
    mean(cms)
end

function d_min_intra(cluster)
    min = Inf
    for i in eachindex(cluster)
        for j in eachindex(cluster)
            if j < i && j != i
                d = Distances.euclidean(cluster[i],cluster[j])
                if d < min
                    min = d
                end
            end
        end
    end
    min
end

function d_min_inter(cluster, rest)
    inter = pairwise(Euclidean(), cluster, rest)
    minimum(inter)
end

"""
penalty fn
"""
function penalty(intra, inter, a = 0.1)
    if inter > 2*intra
        return 0.0
    elseif inter <= 2*intra
        return a
    else
        return (a * (inter - intra)) / intra
    end
end


"""
DM clusters
"""
function dm_clusters(data::AbstractMatrix, clustering::Vector{Vector{Int}})

    Fn = 0.0
    k = length(clustering)

    while(k>2)
        cluster = clustering[k]
        rs = [1:k-1...]
        rest = vcat(clustering[rs]...)
        
        cp = @views data[cluster, :]'
        rp = @views data[rest, :]'

        intra = d_min_intra(cp)
        inter = d_min_inter(cp, rp)

        Fn += penalty(intra, inter)

        k -= 1
    end

    -Fn
end

"""

    Index =  Compactness Measure of Clusters + Distinctness Measure of Clusters

    AR_SD = CM_SD + DM_clusters

    data: is a Matrix (n x d) with n d-dimensional instances
    clustering: is a vector of vector with assignments

"""
function arsd(data::AbstractMatrix, clustering::Vector{Vector{Int}})
    cm = cm_sd(data, clustering)
    dm = dm_clusters(data, clustering)
    # @show cm, dm
    return cm + dm
end


# data = randn(30,2) .* rand(30)*0.001
# clustering = [[1:5...],[6:10...],[11:15...],[16:20...],[21:30...]]
# c_1 = data[clustering[1],:]
# c_1'
# pairwise(Euclidean(), c_1')
# md(c_1')

# cm_sd(data,clustering)
# dm_clusters(data,clustering)
# arsd(data,clustering)
