# experiment 1

6000 true true false 0 0 on 51750P-300k

# no pointers

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.3066275681724137

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
9.078768e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.0021382463793103447

# with pointers
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.5018857216551724

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
1.32896048e8

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.026574968655172417


# experiment 2 on less clusters

sequence = rand(1:4, 40000)

min_sup     = 10000
unique      = true
similar     = true     # for big datasets with small k of Clusters only...
overlapping = false
gap_min     = 0
gap_max     = 0


# without pointers

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.4684543641034483

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
1.8335248e7

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.006984982241379311


# with pointers

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.7535273938275862

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
2.1383248e7

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.0067254348620689654
