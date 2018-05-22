module Validation

    include("betacv.jl")

    export betacv, intra_cluster_weights, inter_cluster_weights, weights

    include("sdbw.jl")

    export sdbw, scattering, dense_bw
    export variance, sqrt_norm, avg_std, medoid, density

    include("crossvalidation.jl")

    export CrossValidation, out_of_time, partition_indices, k_fold_out_of_time
    
end