using Base.Test
using LogClustering.Validation

m = [1.0:104.0...]
M = hcat([1.0:104.0...],[1.0:104.0...])'

out_of_time(m)

partition_indices(m,5)
partition_indices(M,5)

for e in k_fold_out_of_time(m)
    @show e
end

for e in k_fold_out_of_time(M)
    @show e
end

