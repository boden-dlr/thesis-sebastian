include(joinpath(pwd(), "src/episode_mining/rule_mining.jl"))

hueSet = Dict{Array{Int64,1},Array{UnitRange{Int64},1}}(
  [1, 2, 3] => UnitRange{Int64}[1:3, 8:10],
  [1, 2]    => UnitRange{Int64}[1:2, 8:9, 14:15],
  [2, 3]    => UnitRange{Int64}[2:3, 9:10],
  [5, 1]    => UnitRange{Int64}[7:8, 13:14],
  [5, 1, 2] => UnitRange{Int64}[7:9, 13:15])

moSet = Dict{Array{Int64,1},Array{UnitRange{Int64},1}}(
  [2, 4]       => UnitRange{Int64}[15:16],
  [1, 2, 3]    => UnitRange{Int64}[1:3, 8:10],
  [1, 2, 3, 5] => UnitRange{Int64}[1:4],
  [1, 2]       => UnitRange{Int64}[1:2, 8:9, 14:15],
  [5, 1, 2, 3] => UnitRange{Int64}[7:10],
  [5, 1, 2, 4] => UnitRange{Int64}[13:16],
  [3]          => UnitRange{Int64}[3:3, 10:10],
  [2, 3]       => UnitRange{Int64}[2:3, 9:10],
  [5, 1, 2]    => UnitRange{Int64}[7:9, 13:15],
  [2]          => UnitRange{Int64}[2:2, 9:9, 15:15],
  [5, 4]       => UnitRange{Int64}[4:5],
  [4]          => UnitRange{Int64}[5:5, 16:16],
  [1]          => UnitRange{Int64}[1:1, 8:8, 14:14],
  [3, 5]       => UnitRange{Int64}[3:4],
  [5]          => UnitRange{Int64}[4:4, 7:7, 12:12, 13:13],
  [5, 1]       => UnitRange{Int64}[7:8, 13:14],
  [2, 3, 5]    => UnitRange{Int64}[2:4],
  [1, 2, 4]    => UnitRange{Int64}[14:16])

primSet = Dict{Array{Int64,1},Array{UnitRange{Int64},1}}(
    [3] => UnitRange{Int64}[3:3, 10:10],
    [4] => UnitRange{Int64}[5:5, 16:16],
    [1] => UnitRange{Int64}[1:1, 8:8, 14:14],
    [5] => UnitRange{Int64}[4:4, 7:7, 12:12, 13:13],
    [2] => UnitRange{Int64}[2:2, 9:9, 15:15])

highConf = mine_high_conf(moSet, moSet, 0.2)
sort(highConf, by=t->t[2], rev=true)
