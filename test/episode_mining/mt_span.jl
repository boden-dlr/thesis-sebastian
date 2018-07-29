
include(joinpath("src","episode_mining","mt_span.jl"))

max_duration = 8
min_support  = 2
max_repetition = 0
max_gap = 0

#                A B C E D G E A B C F E E A B D 
sequence = Int64[1,2,3,5,4,8,5,1,2,3,7,5,5,1,2,4]
#                0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1
#                1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6

# utilities = Float64[0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8]
k = maximum(sequence)
# utilities = rand(k)
# min_utililty = 0.2
utilities = fill(1.0, k)
min_utililty = 0.0

data = readdlm("data/embedding/playground/2018-07-25_51750_assignments_and_reconstruction_error.csv")
# min_utililty = 8.005383703975682e-5
# min_utililty = 0.000038764
# min_utililty = 0.00004945573
# min_utililty = 0.00005      # max_duration:10
# min_utililty = 0.00005308   # max_duration:20
min_utililty = 7.468059462914433e-5

# data = readdlm("data/embedding/playground/2018-07-28_6073_assignments_and_reconstruction_error.csv")
# min_utililty = 3.3399087787414806e-5
# min_utililty = 0.0

sequence = map(n->convert(Int64,n), data[:,1])
k = maximum(sequence)
vertical = Index.invert(sequence)
max_sup = maximum(map(length, values(vertical)))
utilities = Vector{Float64}(k)
for key in keys(vertical)
    utilities[key] = max_sup+1 - length(vertical[key])
    # utilities[key] = length(vertical[key])
end

# utilities = map(n->convert(Float64,n), data[:,2])
# max_utilitly = maximum(utilities)
# utilities = map(u->(u/max_utilitly)^100, utilities)


# big rocks: 715, 
# blacklist_51750 = [468, 493, 512, 528, 547, 565, 575, 584, 593, 603, 620, 629, 630, 631, 632, 643, 646, 674, 715, 717, 718, 721, 722, 728, 729, 731, 732, 735, 736, 770]
# greylist_51750 = [616, 638, 691, 714, 739, 740, 743, 746, 749, 769, 773, 776, 786, 787, 800, 812, 815]
# for event in sort(collect(keys(vertical)))
#     println(event, "\t", event in blacklist_51750, "\t", event in greylist_51750, "\t", length(vertical[event]))
# end
# blacklist_51750, greylist_51750 = [], []

# event = 702
# occs = Vector{UnitRange{Int64}}()
# for (i,e) in enumerate(sequence)
#     if e == event
#         push!(occs, i:i)
#     end
# end
# occs
# prefix = [event]
# moSet = Dict([event] => occs)


# utilities = rand(k)
# utilities = fill(1.0, k)

# hueSet = Dict{Vector{Int64},Vector{Intervall}}()

# using ProfileView
# Profile.clear()

# ts = Vector{Tuple{Vector{Int},Float64,Base.GC_Diff}}()
# @show "total"
# @profile
begin
    hueSet = @time mt_span(
        sequence,       # ES - event sequence
        utilities,      # external utilities per event
        max_duration,   # maximal time duration
        min_support,    # absolute minumum support
        min_utililty,   # min_utililty
        max_repetition, # maximum repetitions for each event
        max_gap;        # maximal gap
        verbose = false,
        parallel = false)
end
# secs = map(t -> t[2], ts)
# @show indmax(secs)
# @show minimum(secs)
# @show median(secs)
# @show mean(secs)
# @show maximum(secs)
# @show sum(secs)

# ProfileView.view()
# while true
#     sleep(5)
# end


sort(collect(hueSet), by=kv->(length(kv[1]),length(kv[2])), rev=false)

sort(collect(hueSet), by=kv->(length(kv[2]),length(kv[1])), rev=false)

# hueSet[[1,2,5]]         # sup:2
# assert(length(hueSet[[1, 2, 5]]) == 2)

# hueSet[[5,5]]           # sup:3
# assert(length(hueSet[[5, 5]]) == 3)

# hueSet[[1, 2, 3, 1, 2]] # sup:1 -overlapping candidate
# assert(length(hueSet[[1, 2, 3, 1, 2]]) == 1)

hueSet
