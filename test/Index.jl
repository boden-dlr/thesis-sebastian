using Base.Test
using LogClustering.Index

function count_pairs(d)
    length(keys(d))
end

function count_support(d)
    reduce((prev,list) -> prev + length(list), 0, values(d))
end

data = [1,2,3,5,4,5,6,1,2,3,7,6,5,4,1,2]

result = Index.pairs(data)
expected = Index.pairs(data, gap=length(data))
assert(result == expected)
assert(41 == count_pairs(result))
assert(64 == count_support(result))

result = Index.pairs(data, gap=0)
assert(11 == count_pairs(result))
assert(15 == count_support(result))

result = Index.pairs(data, gap=1)
assert(22 == count_pairs(result))
assert(28 == count_support(result))

result = Index.pairs(data, unique=false)
assert(47 == count_pairs(result))
assert(70 == count_support(result))
assert(length(result[(5,7)]) == 1)

result = Index.pairs(data, unique=false, overlapping=true)
assert(47 == count_pairs(result))
assert(120 == count_support(result))
assert(length(result[(5,7)]) == 2)

data = rand(1:250, 5000)
@time result = Index.pairs(data, gap=0)
count_pairs(result)
count_support(result)

@time result = Index.pairs(data)
count_pairs(result)
count_support(result)
