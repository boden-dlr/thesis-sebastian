using Base.Test

# ----------------------------------------------------------------------
# Array vs. Vector test

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
# Array vs. Tuple keys
#
using DataStructures

# make arrays comparable for sort
function Base.isless(as::Array{Int64,1}, bs::Array{Int64,1})
    A = length(as)
    B = length(bs)
    for i = 1:min(A,B)
        if as[i] > bs[i]
            return false
        end
    end
    if A < B
        return true
    else
        return false
    end
end

@time Base.isless((1,2,3), (1,2,3))

@time assert(isless(Int64[], [1]) == true)
@time assert(isless([1,2], [1,2,3]) == true)
@time assert(isless([1,2], [1,2,3,4,5]) == true)

@time assert(isless([1,2], [1]) == false)
@time assert(isless([1,2,3], [1,2]) == false)
@time assert(isless([1,5], [1,2,3,4,5]) == false)

r = 1:10000
as = [i for i in 1:10000]
bs = vcat([i for i in 1:10000],10001)
test1 = Vector()
for i in r
    push!(test1, @timed isless(as, bs))
end
bs = [0]
test2 = Vector()
for i in r
    push!(test2, @timed isless(as, bs))
end
reduce((p,t)-> p+t[2], 0.0, test1) / length(test1)
reduce((p,t)-> p+t[2], 0.0, test2) / length(test2)

reduce((p,t)-> p+t[3], 0.0, test1) / length(test1)
reduce((p,t)-> p+t[3], 0.0, test2) / length(test2)


dt = Dict{Tuple,Tuple{Int64,UnitRange{Int64},Array{Int64,1}}}()
dt[(1,2,4)] = (1,1:1,Int64[])
dt[(1,)] = (1,1:1,Int64[])
dt[(1,2)] = (1,1:1,Int64[])
dt[(1,2,3)] = (1,1:1,Int64[])
# NOTE: it is not possible to add an array diectly
# da[[1,5]] = (1,1:1,Int64[]) # ERROR: MethodError: Cannot `convert` an object of type Array{Int64,1} to an object of type Tuple
dt

da = Dict{Array{Int64,1},Tuple{Int64,UnitRange{Int64},Vector{Int64}}}()
da[[1,2,4]] = (1,1:1,Int64[])
da[[1,]] = (1,1:1,Int64[])
da[[1,2]] = (1,1:1,Int64[])
da[[1,2,3]] = (1,1:1,Int64[])
da
# sort(lt=myisless)
# ERROR: MethodError: no method matching isless(::Array{Int64,1}, ::Array{Int64,1})

dv = Dict{Vector{Int64},Tuple{Int64,UnitRange{Int64},Vector{Int64}}}()
dv[[1,2,4]] = (1,1:1,Int64[])
dv[[1,]] = (1,1:1,Int64[])
dv[[1,2]] = (1,1:1,Int64[])
dv[[1,2,3]] = (1,1:1,Int64[])
dv

@time DataStructures.OrderedDict(sort(dt))
@time DataStructures.OrderedDict(sort(da))
@time DataStructures.OrderedDict(sort(dv))

# ------------------------------------------------------------------------------
# Extend a Pattern and Array to Tuple

a = [1,2,3]
tuple(a...)
# Extend tuple
extended = tuple(a..., 4)
extended = tuple(extended..., 5)

function extend_tuple(itr, e)
    tuple(itr..., e)
end

t = ()
tup_t = @timed for i = 1:10000
    t = extend_tuple(t, i)
end

v = Vector()
vec_t = @timed for i = 1:10000
    append!(v,i)
end

tup_t
vec_t
