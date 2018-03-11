using Clustering
using Plots
# gr()
using Rsvg
plotlyjs()

srand(1234)

path = "data/kate/"
filename = "51750S_6154V_148N_3K_15E_1234seed_embedded_KATE.csv"
name = splitext(filename)[1]
# points = randn(2, 10000)
# points = readcsv("data/kate/old/kate_8780_68545_129_3_30.csv")
# points = readcsv("data/kate/7614S_2633V_220N_3K_10E_1234seed_clustered_KATE.csv")
# points = readcsv("data/kate/7614S_2623V_237N_3K_10E_1234seed_embedded_KATE.csv")
points = readcsv(string(path, filename))
points = transpose(points)[:,1:5000]
# points = transpose(points)
P = size(points)[2]

algorithm = :dbscan

if algorithm == :dbscan
    clusters = dbscan(
        points,
        10e-5,
        min_neighbors = 2,
        min_cluster_size = 1)
elseif algorithm == :fuzzy_cmeans
    k = 20
    clusters = fuzzy_cmeans(
        points,
        k,
        2.0)
end


# @show length(clusters)

points_clustered = zeros(Int64, P)

if algorithm == :dbscan
    for (c,cluster) in enumerate(clusters)
        
        for i in cluster.core_indices
            points_clustered[i] = c
        end
        for i in cluster.boundary_indices
            points_clustered[i] = c
        end
    end
elseif algorithm == :fuzzy_cmeans
    # @show clusters.centers
    points_clustered[1] = clusters.centers[1:k]
    points_clustered[2] = clusters.centers[k+1:2*k]
    points_clustered[3] = clusters.centers[2*k+1:3*k]
    @show length(clusters.weights)
end

writecsv(string(path, name, "_clustered_", "$algorithm\_", P, "P.csv"), points_clustered)

colors = fill(length(clusters), P) .- points_clustered

p = scatter3d(points[1,:], points[2,:], points[3,:],
    # marker_z = 1:length(clusters),
    # zcolor = 1:length(clusters))
    # color = 1:length(clusters))
    marker_z = colors)
    # color = colors)
# current()
savefig(p, string(path, name, "_clustered_", "$algorithm\_", P, "P.png"))
