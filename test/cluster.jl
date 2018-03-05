using Clustering
using Plots
gr()

srand(1234)

# points = randn(2, 10000)
points = readcsv("data/kate/kate_8780_68545_129_3_30.csv")
points = transpose(points)[:,1:1000]
P = size(points)[2]

clusters = dbscan(
    points,
    0.0001,
    min_neighbors = 3,
    min_cluster_size = 1)
# # , min_neighbors = 3, min_cluster_size = 20)
# @show length(clusters)

points_clustered = zeros(Int64, P)

for (c,cluster) in enumerate(clusters)
    # for i in cluster.core_indices
    #     points_clustered[i] = c
    # end
    for i in cluster.boundary_indices
        points_clustered[i] = c
    end
end

scatter3d(points[1,:], points[2,:], points[3,:],
    zcolor=points_clustered)
# current()
