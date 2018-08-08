
# @views - dummy

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
2.6690295209655175

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
5.1878872e8

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.305969108137931

# @inbounds - dummy

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
2.590768692931035

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
5.18807792e8

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.3267661280344828

# Experiment 1 - ohne utility

5 rounds
51750P_300k.csv

min_sup     = 5000 #round(Int64,50000/2^15)
unique      = true
unique_n    = 1
similar     = true
overlapping = false
gap         = 0
set         = :all

# with lookuptable

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
4.341756935

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
1.09329216e8

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.08652548

# without lookuptable
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
1.83512486

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
6.7169568e7

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.02936433425

# Experiment 2 - mit local utility

5 rounds
51750P_300k.csv

min_utility = 0.999 
min_sup     = 340
unique      = true
unique_n    = 2
similar     = false
overlapping = false
gap         = 0
set         = :all

# with lookuptable
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
5.058931109

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
1.95136928e8

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.103541104

# without lookuptable

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
1.90735349825

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
6.2950048e7

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.0171642445

# Experiment 3 - mit utility

30 rounds
51750P_300k.csv

min_utility = 0.999 # 000337
min_sup     = 1 #round(Int64,50000/2^15)
unique      = true
unique_n    = 2
similar     = false
overlapping = false
gap         = 1
set         = :all

# with lookuptable - indirect access - 5 rounds

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
9.62544315825

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
1.114371064e9

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.2645386515

# with lookuptable - direct access - 1 rounds
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
17.372032536

Main> avg_bytes = reduce((p,t)-> p+t[2], 0, timing) / length(timing)
2.759272348e10

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
3.244002089

Main> avg_poolalloc = reduce((p,t)-> p+t[4].poolalloc, 0, timing) / length(timing)
6.5456572e7

# without lookuptable - 30 rounds

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
5.599283223482758

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
5.61987592e8

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.17821757096551724


# Experiment 4 - ohne utility

rounds 30
data 16

min_sup     = 2 #round(Int64,50000/2^15)
unique      = true
unique_n    = 2
similar     = true
overlapping = false
gap         = -1
set         = :all

# with lookuptable - indirect
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.010013533939799337

Main> avg_bytes = reduce((p,t)-> p+t[2], 0, timing) / length(timing)
1.693104e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.0006595634247491637

Main> avg_poolalloc = reduce((p,t)-> p+t[4].poolalloc, 0, timing) / length(timing)
46873.0

# with lookuptable - direct
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.010702963160535114

Main> avg_bytes = reduce((p,t)-> p+t[2], 0, timing) / length(timing)
1.6812e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.0007638613645484951

Main> avg_poolalloc = reduce((p,t)-> p+t[4].poolalloc, 0, timing) / length(timing)
46129.0

# without lookuptable
79 results

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.009885285827586208

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
1.539696e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.001321242448275862

Main> avg_poolalloc = reduce((p,t)-> p+t[4].poolalloc, 0, timing) / length(timing)
43037.0

