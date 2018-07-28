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
