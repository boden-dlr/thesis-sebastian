module Validation

    include("betacv.jl")

    export betacv, intra_cluster_weights, inter_cluster_weights, weights

    include("sdbw.jl")

    export sdbw, scattering, dense_bw
    export variance, sqrt_norm, avg_std, medoid, density
    
end