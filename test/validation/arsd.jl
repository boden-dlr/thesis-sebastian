using Distributions
using Plots
gr()
using Clustering
using LogClustering.ClusteringUtils
using LogClustering.Validation


n = 200
xs = Vector()
p_data = nothing
for i in 1:5
    μs = rand(-10:10, 2)
    σs = rand(0.5:0.1:3.0, 2)
    M = vcat(map(i->Distributions.rand(Normal(μs[i],σs[i]), 1, n), 1:2)...)
    push!(xs, M)
    if i == 1
        p_data = scatter(M[1,:], M[2,:])
    else
        p_data = scatter!(M[1,:], M[2,:])
    end
end
display(p_data)


D = hcat(xs...)
bs = Vector()
# for k in 2:10
for eps in 1.0:0.2:2.5
    info(eps)
    cs = Vector()
    for _ in 1:10
        # result = kmeans(D, k)
        # p_clustered = scatter(D[1,:], D[2,:], marker_z = result.assignments)
        # display(p_clustered)
        # C = assignments_to_clustering(result.assignments)

        rs = dbscan(D, eps)
        C = map(r-> [r.core_indices..., r.boundary_indices...], rs)
        assignments = clustering_to_assignments(C)

        p_clustered = scatter(D[1,:], D[2,:], marker_z = assignments)
        display(p_clustered)
        sleep(1)

        ar = arsd(D', C)
        
        @show length(C)

        push!(cs, ar)

        # DC = [view(D,:,c) for c in C]
        # p = scatter(DC[1][1,:], DC[1][2,:])
        # display(p)
        # sleep(3)
    end
    push!(bs, maximum(cs))
end
plot(bs)

