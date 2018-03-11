using Clustering
using Plots
gr()
# using Rsvg
# plotlyjs()
srand(1234)

path = "data/kate/"
filename = "51750S_6154V_148N_3K_15E_1234seed_embedded_KATE.csv"
name = splitext(filename)[1]
points = readcsv(string(path, filename))
# points = transpose(points)[:,1:5000]
points = transpose(points)
P = size(points)[2]
k = 300
clustered = kmeans(points,k)

p = scatter3d(
    points[1,:], points[2,:], points[3,:],
    label = "data (colored by cluster ID)",
    marker_z = clustered.assignments)
savefig(p, string(path, name, "_clustered_", "kmeans_", P, "P", k, "k", ".png"))

x,y,z = Vector{Float64}(), Vector{Float64}(), Vector{Float64}()
weights = Vector{Float64}()

for (i,w) in enumerate(clustered.cweights)
    if w > 1000.0
        push!(x, clustered.centers[1,i])
        push!(y, clustered.centers[2,i])
        push!(z, clustered.centers[3,i])
        push!(weights, w)
    end
end

n = length(x)

cluster = scatter3d(
    x,y,z,
    label = string("k-means centroids (", n, ")"),
    marker_z = weights)

savefig(
    cluster,
    string(
        path, name,
        "_clustered_", "kmeans_centers_",
        P, "P_", k, "k_", n, "n",
        ".png")
    )
