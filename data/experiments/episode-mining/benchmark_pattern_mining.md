# MV-Span

# Experiment 1

sequence = rand(1:1000, 50000)
min_sup     = 70
unique      = true
similar     = false
overlapping = false
gap         = 0

## mit findfirst random data

### 1.
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.7042229632828282

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
3.15156368e8

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.05604880626262628

### 2.
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.7014897340909092

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
3.15156368e8

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)



## ohne findfirst random data

### 1.
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.07374355540404043

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
6.700064e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.001467587424242424

### 2.
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.06600096455555554

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
5.371936e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.0016917104949494947



# Experiment 2

data = readcsv("data/kate/51750S_6154V_148N_3K_15E_1234seed_embedded_KATE_clustered_kmeans_51750P_300k.csv")
sequence = map(n->convert(Int64,n), data[:,1])

min_sup     = 8000
unique      = true
similar     = false
overlapping = false
gap         = 0

## ohne findfirst - real data

### 1.
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.3289965820808081

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
9.079328e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.0024692730909090903

### 2.
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.3112665223838384

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
9.079328e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.0021315364848484846

## mit findfirst - real data

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
4.934044713242425

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
4.031939328e9

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.3951022665454546


# Experiment 3 - kein min für start gap >= 0

data = readcsv("data/kate/51750S_6154V_148N_3K_15E_1234seed_embedded_KATE_clustered_kmeans_51750P_300k.csv")
sequence = map(n->convert(Int64,n), data[:,1])
min_sup     = 8000
unique      = true
similar     = false
overlapping = false
gap         = 0

## 1.
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.35105543348484863

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
9.079328e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.0020279791919191924

## 2.
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.31755947766666676

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
9.079328e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.002121458333333333



# Experiment 3 - similar true - early catch


data = readcsv("data/kate/51750S_6154V_148N_3K_15E_1234seed_embedded_KATE_clustered_kmeans_51750P_300k.csv")
sequence = map(n->convert(Int64,n), data[:,1])
min_sup     = 8000
unique      = true
similar     = true
overlapping = false
gap         = 0

## 1.
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.31541188266666664

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
9.078768e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.001958043525252526


# Experiment 4


min_sup     = 70
unique      = true
similar     = false
overlapping = false
gap         = 0

#  sequence = rand(1:1000, 50000)

### 1.
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.07681265149494947

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
8.04448e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.0018003382424242424

### 2.
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.06565345912121212

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
6.69128e6

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.0014529750404040402

## vs. sequence = rand(1:10, 50000)

### 1.
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.2748980653737375

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
1.0541608e7

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.003085982323232324

## vs. sequence = rand(1:4, 50000)

### 1.
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.3870971885555557

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
1.5260616e7

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.005007288959595961


# Experiment 5 - last position known

sequence = rand(1:4, 50000)
min_sup     = 70
unique      = true
similar     = false
overlapping = false
gap         = 0

## 1. ohne view
Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
1.1825244042121208

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
4.45428748e9

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.21641440729292935

## 2. mit view

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.8310142623030305

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
1.7020184e7

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.006945941232323233

## 3. ohne counting

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.3573582894242425

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
1.5103384e7

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
0.005687719545454547

### 4. moved union!(foundat_all) after recursion

Main> avg_time  = reduce((p,t)-> p+t[1], 0.0, timing) / length(timing)
0.41123502027272724

Main> avg_bytes = reduce((p,t)-> p+t[2], 0.0, timing) / length(timing)
1.5199976e7

Main> avg_gctime = reduce((p,t)-> p+t[3], 0.0, timing) / length(timing)
