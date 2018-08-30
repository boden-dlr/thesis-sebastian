Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.3422850287241379

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
9.078768e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.004732510724137932



# trading time against space

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.33369984313793094

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
1.32896032e8

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.020712176862068964





Main> reduce((p,l)->p+length(l), 0, flatmap(identity, collect(values(db))))
51

DataStructures.OrderedDict{Array{Int64,1},Array{Array{Int64,1},1}} with 9 entries:
  [4]             => Array{Int64,1}[[5], [16]]
  [3]             => Array{Int64,1}[[3], [10]]
  [1, 2, 3, 5, 4] => Array{Int64,1}[[1, 2, 3, 4, 5], [8, 9, 10, 13, 16]]
  [1, 2, 5]       => Array{Int64,1}[[1, 2, 4], [8, 9, 12]]
  [5, 1, 2]       => Array{Int64,1}[[7, 8, 9], [12, 14, 15]]
  [5, 5, 1]       => Array{Int64,1}[[4, 7, 8], [12, 13, 14]]
  [5, 5, 2]       => Array{Int64,1}[[4, 7, 9], [12, 13, 15]]
  [2, 3, 5]       => Array{Int64,1}[[2, 3, 4], [9, 10, 12], [9, 10, 13]]
  [2, 4]          => Array{Int64,1}[[2, 5], [15, 16]]




Main> reduce((p,l)->p+length(l), 0, flatmap(identity, collect(values(db))))
23
DataStructures.OrderedDict{Array{Int64,1},Array{Array{Int64,1},1}} with 5 entries:
  [4]          => Array{Int64,1}[[5], [16]]
  [2]          => Array{Int64,1}[[2], [9], [15]]
  [3]          => Array{Int64,1}[[3], [10]]
  [5]          => Array{Int64,1}[[4], [7], [12], [13]]
  [1, 2, 3, 5] => Array{Int64,1}[[1, 2, 3, 4], [8, 9, 10, 12], [8, 9, 10, 13]]
  
  
  
  
  
  
DataStructures.OrderedDict{Array{Int64,1},Array{Array{Int64,1},1}} with 7 entries:
  [4]          => Array{Int64,1}[[5], [16]]
  [1, 2, 3, 5] => Array{Int64,1}[[1, 2, 3, 4], [8, 9, 10, 12]]
  [1, 3, 5]    => Array{Int64,1}[[1, 3, 4], [8, 10, 12]]
  [5, 1, 2]    => Array{Int64,1}[[7, 8, 9], [12, 14, 15]]
  [5, 2]       => Array{Int64,1}[[7, 9], [13, 15]]
  [3, 5]       => Array{Int64,1}[[3, 4], [10, 12]]
  [2, 3, 5]    => Array{Int64,1}[[2, 3, 4], [9, 10, 12]]
  
  
DataStructures.OrderedDict{Array{Int64,1},Array{Array{Int64,1},1}} with 8 entries:
  [4]          => Array{Int64,1}[[5], [16]]
  [1, 2, 3, 5] => Array{Int64,1}[[1, 2, 3, 4], [8, 9, 10, 12]]
  [1, 3, 5]    => Array{Int64,1}[[1, 3, 4], [8, 10, 12]]
  [5, 1, 2, 4] => Array{Int64,1}[[12, 14, 15, 16], [13, 14, 15, 16]]
  [5, 1, 4]    => Array{Int64,1}[[12, 14, 16], [13, 14, 16]]
  [5, 2]       => Array{Int64,1}[[7, 9], [13, 15]]
  [3, 5]       => Array{Int64,1}[[3, 4], [10, 12]]
  [2, 3, 5]    => Array{Int64,1}[[2, 3, 4], [9, 10, 12]]  
  
  
  
  
  
min_sup     = 2 #round(Int64,50000/2^15)
unique      = false
similar     = true
overlapping = true
gap         = 1

# original

Main> reduce((p,l)->p+length(l), 0, flatmap(identity, collect(values(db))))
44
DataStructures.OrderedDict{Array{Int64,1},Array{Array{Int64,1},1}} with 8 entries:
  [4]          => Array{Int64,1}[[5], [16]]
  [1, 2, 3, 5] => Array{Int64,1}[[1, 2, 3, 4], [8, 9, 10, 12]]
  [1, 3, 5]    => Array{Int64,1}[[1, 3, 4], [8, 10, 12]]
  [5, 1, 2, 4] => Array{Int64,1}[[12, 14, 15, 16], [13, 14, 15, 16]]
  [5, 1, 4]    => Array{Int64,1}[[12, 14, 16], [13, 14, 16]]
  [5, 2]       => Array{Int64,1}[[7, 9], [13, 15]]
  [3, 5]       => Array{Int64,1}[[3, 4], [10, 12]]
  [2, 3, 5]    => Array{Int64,1}[[2, 3, 4], [9, 10, 12]]  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
