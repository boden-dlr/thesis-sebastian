times = 100000

a = rand(1:1000, 5)
b = Array{Int64}(6)
c = Array{Int64}(6)

# function test(e, )
#     @timed for _ = 1:times e end
# end

#
# test - assigment to pre-allocated array
#

@time b[1:5] = a
@timed for _ in 1:times b[1:5] = a end
b

@time b[1:5] = copy(a)
@timed for _ in 1:times b[1:5] = copy(a) end
b

# 
# test - index vs. `end`
# 

@time b[6] = 6
@timed for _ in 1:times b[6] = 6 end

@time c[end] = 6
@timed for _ in 1:times c[end] = 6 end


#
# Parallel workers
#

if nprocs() == 1
    addprocs(3)
end

function external()
    1+1
end

@everywhere module M
    function mutate!(d,p)
        e = external()
        d[p] = fill(p:p, p)
    end
end

d = Dict{Int64,Vector{UnitRange{Int64}}}()
ps = [1:10...]
pmap( p -> M.mutate!(d,p), ps)


# 
# Multi-Threading
# 

# export JULIA_NUM_THREADS=4

Threads.nthreads()

a = zeros(10)
Threads.@threads for i = 1:10
    a[i] = Threads.threadid()
end
a