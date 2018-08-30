min_sup     = 2
unique      = true
unique_n    = 2
similar     = true
overlapping = false
gap         = -1
set         = :all

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.009745120210702344

Main> avg_bytes = reduce((p,t)-> p+t[2], 0, timing) / length(timing)
1.63864e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.0005250670367892976

Main> avg_poolalloc = reduce((p,t)-> p+t[4].poolalloc, 0, timing) / length(timing)
46129.0


# vcat

min_sup     = 1
unique      = true
unique_n    = 2
similar     = true
overlapping = false
gap         = 1
set         = :all

# 1
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.08380904624749166

Main> avg_bytes = reduce((p,t)-> p+t[2], 0, timing) / length(timing)
1.52504e7

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.005876100809364551

Main> avg_poolalloc = reduce((p,t)-> p+t[4].poolalloc, 0, timing) / length(timing)
414451.0

# 2
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.08734603814715713

Main> avg_bytes = reduce((p,t)-> p+t[2], 0, timing) / length(timing)
1.52504e7

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.005669553745819399

Main> avg_poolalloc = reduce((p,t)-> p+t[4].poolalloc, 0, timing) / length(timing)
414451.0

# pre-alloc - verbose for

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.01658256455518396

Main> avg_bytes = reduce((p,t)-> p+t[2], 0, timing) / length(timing)
5.363952e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.001543396294314381

Main> avg_poolalloc = reduce((p,t)-> p+t[4].poolalloc, 0, timing) / length(timing)
91141.0

# pre-alloc to index

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.016907130036789293

Main> avg_bytes = reduce((p,t)-> p+t[2], 0, timing) / length(timing)
5.363952e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.001688500946488294

Main> avg_poolalloc = reduce((p,t)-> p+t[4].poolalloc, 0, timing) / length(timing)
91141.0
