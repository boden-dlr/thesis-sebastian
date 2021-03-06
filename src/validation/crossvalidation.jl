using IterTools


struct CrossValidation{T}
    train::T
    test::T
    i::Int64
    k::Int64
end


function out_of_time(data::AbstractArray, ratio=0.3)
    N = length(data)
    split = round(Int64, N*(1.0-ratio))
    train_rng = 1:split
    test_rng = split+1:N
    train = view(data, train_rng)
    test = view(data, test_rng)
    CrossValidation(train, test, 1, 1)
end


function partition_indices(data::AbstractArray, n::Integer)
    l = length(data)
    s = round(Int, l/n)
    ps = Vector{UnitRange{Int64}}()
    for i = 1:n
        from = (i-1)*s+1
        to = min((i-1)*s+s, l)
        push!(ps,from:to)
    end
    ps
end


function partition_indices(data::AbstractMatrix, n::Integer)
    _,l = size(data)
    s = round(Int, l/n)
    ps = Vector{UnitRange{Int64}}()
    for i = 1:n
        from = (i-1)*s+1
        to = min((i-1)*s+s, l)
        push!(ps,from:to)
    end
    ps
end


k_fold_out_of_time(data::AbstractArray, k = 5) = Channel(ctype=CrossValidation{typeof(data)}) do c
    n = length(data)
    if n < k
        warn("k ($k) should be smaller or equal to n ($n). Setting k to $n.")
        k = min(k,n)
    end
    s = round(Int, n/k)
    ps = partition_indices(data, k)
    ts = [IterTools.subsets([1:k...],k-1)...]
    for i in 1:k
        test = k+1-i
        train = ts[i]
        push!(c, CrossValidation(data[union(ps[train]...)], data[ps[test]], i, k))
    end
end


k_fold_out_of_time(data::AbstractMatrix, k = 5) = Channel(ctype=CrossValidation{typeof(data)}) do c
    d,n = size(data)
    if n < k
        warn("k ($k) should be smaller or equal to n ($n). Setting k to $n.")
        k = min(k,n)
    end
    s = round(Int, n/k)
    ps = partition_indices(data, k)
    ts = [IterTools.subsets([1:k...],k-1)...]
    for i in 1:k
        test = k+1-i
        train = ts[i]
        push!(c, CrossValidation(data[:,union(ps[train]...)], data[:,ps[test]], i, k))
    end
end
