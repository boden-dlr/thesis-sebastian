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
  


# Experiment 2

rounds 30

data = readcsv("data/kate/51750S_6154V_148N_3K_15E_1234seed_embedded_KATE_clustered_kmeans_51750P_300k.csv")

min_sup     = 8000
unique      = true
similar     = true     # for big datasets with small k of Clusters only...
overlapping = false
gap         = 0

# with pointers
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
1.0250946281034483

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
2.903246208e9

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.27565382837931035

# without pointers

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.3422850287241379

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
9.078768e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.004732510724137932


# with pointers, but less allocations
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.4969568460000001

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
1.32896592e8

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.03222219213793104
