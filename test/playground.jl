
function push_array(a::Array, r)
    for i in r
        push!(a,i)
    end
end

function push_vector(v::Vector, r)
    for i in r
        push!(v,i)
    end
end

rounds = 10000
r = 1:1000000

results_da = Vector()
for round in 1:rounds
    da = Dict{Tuple,Tuple{Int64,UnitRange{Int64},Array{Int64,1}}}()
    da[(1,2)] = (1,1:1,Int64[])
    push!(results_da, @timed push_array(da[(1,2)][3], r))
end

results_dv = Vector()
for round in 1:rounds
    dv = Dict{Tuple,Tuple{Int64,UnitRange{Int64},Vector{Int64}}}()
    dv[(1,2)] = (1,1:1,Vector{Int64}())
    push!(results_dv, @timed push_vector(dv[(1,2)][3], r))
end

reduce((p,t)-> p+t[2], 0.0, results_da) / length(results_da)
reduce((p,t)-> p+t[2], 0.0, results_dv) / length(results_dv)

# ------------------------------------------------------------------------------
using DataStructures

da = Dict{Tuple,Tuple{Int64,UnitRange{Int64},Array{Int64,1}}}()
da[(1,2,4)] = (1,1:1,Int64[])
da[(1,)] = (1,1:1,Int64[])
da[(1,2)] = (1,1:1,Int64[])
da[(1,2,3)] = (1,1:1,Int64[])
da[[1,5]] = (1,1:1,Int64[])
da
DataStructures.OrderedDict(sort(collect(da)))

da = Dict{Array,Tuple{Int64,UnitRange{Int64},Array{Int64,1}}}()
da[[1,2,4]] = (1,1:1,Int64[])
da[[1,]] = (1,1:1,Int64[])
da[[1,2]] = (1,1:1,Int64[])
da[[1,2,3]] = (1,1:1,Int64[])
da
DataStructures.OrderedDict(sort(collect(da)))
