using NearestNeighbors
using LogClustering.Validation
using Flux.Tracker

l = 3
n = 1000
data = randn(l,n)
# data = [
#     1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0;
#     1.1 2.1 3.1 4.1 5.1 6.1 7.1 8.1 9.1;
#     1.2 2.2 3.2 4.2 5.2 6.2 7.2 8.2 9.2;
# ]
# min = minimum(data)
# max = maximum(data)
# randn(min:0.001:max, (3, 10))

balltree = BallTree(data)
k = 10
centroids = hcat(map(r-> data[:,r], rand(1:n, 1000))...)
knnr = knn(balltree, centroids, k)

soft = Dict{Int64,Array{Array{Float64,1},1}}()
for (i,knn) in enumerate(knnr[1])
    points = map(n->data[:,n],knn)
    soft[i] = points
end

C_soft = Clustering(length(soft), soft)

hard = Dict{Int64,Array{Array{Float64,1},1}}()
used = Vector{Int64}()
for (i, knn) in enumerate(knnr[1])
    points = Vector{Array{Float64,1}}()
    for nn in knn
        if !(nn in used)
            push!(used, nn)
            push!(points, data[:,nn])
        end
    end
    hard[i] = points
end

for (k,v) in collect(hard)
    if length(v) == 0
        delete!(hard, k)
    end
end

C_hard = Clustering(length(hard), hard)

length(soft)
mean(map(length, values(soft)))
median(map(length, values(soft)))

length(hard)
length(used) / n
mean(map(length, values(hard)))
median(map(length, values(hard)))

@time betacv(C_soft)
@time betacv(C_hard)
