using Base.Test
using LogClustering.Pattern

data = [1,2,3,5,4,5,6,1,2,3,7,6,5,4,1,2]

result = Pattern.mine_recurring(data,2)

data = rand(1:100, 50000)
@time result = Pattern.mine_recurring(data,11)
