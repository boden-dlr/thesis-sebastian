min_sup     = 2
unique      = false
similar     = true
overlapping = false
gap         = 1
  
# original
 36
 DataStructures.OrderedDict{Array{Int64,1},Array{Array{Int64,1},1}} with 7 entries:
  [4]          => Array{Int64,1}[[5], [16]]
  [1, 2, 3, 5] => Array{Int64,1}[[1, 2, 3, 4], [8, 9, 10, 12]]
  [1, 3, 5]    => Array{Int64,1}[[1, 3, 4], [8, 10, 12]]
  [5, 1, 2]    => Array{Int64,1}[[7, 8, 9], [12, 14, 15]]
  [5, 2]       => Array{Int64,1}[[7, 9], [13, 15]]
  [3, 5]       => Array{Int64,1}[[3, 4], [10, 12]]
  [2, 3, 5]    => Array{Int64,1}[[2, 3, 4], [9, 10, 12]]


# pointers[s_ext] = c_pos
21
DataStructures.OrderedDict{Array{Int64,1},Array{Array{Int64,1},1}} with 6 entries:
  [4]          => Array{Int64,1}[[5], [16]]
  [2]          => Array{Int64,1}[[2], [9], [15]]
  [3]          => Array{Int64,1}[[3], [10]]
  [5]          => Array{Int64,1}[[4], [12]]
  [1, 2, 3, 5] => Array{Int64,1}[[1, 2, 3, 4], [8, 9, 10, 12]]
  [5, 2]       => Array{Int64,1}[[7, 9], [13, 15]]
  

