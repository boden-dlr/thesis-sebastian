using LogClustering: Index


function support(moSet, episode)
    length(moSet[episode])
end

function relative_support(sequence, moSet, episode)
    support(moSet,episode) / length(sequence)
end

function utility(utilities, episode)
    u = 0.0
    for event in episode
        u = u + utilities[event] # external utility
    end
    u
end

function relative_utility(total_utility, utilities, episode)
    utility(utilities, episode) / total_utility
end

function total_utility(sequence, utilities)
    tu = 0.0
    for event in sequence
        tu += utilities[event]
    end
    tu
end

# Episode Weighted Utility
function ewu(total_utility, utilities, episode, moSet)
    (utility(utilities, episode) * length(moSet[episode])) / total_utility
end

# IESC (Improved estimation of EWU for S-Concatenation)
# 
# IESC(α) = (u(α) + u(SES(α)))/u(CES).
# 
function iesc(total_utility, utilities, alpha, SES)
    (utility(utilities, alpha) + utility(utilities, SES)) / total_utility
end

# transaction/sequence weighted utility (TWU/SWU)
# function swu()
# end

Intervall = UnitRange{Int64}

function s_concatenation!(
    sequence::Vector{Int64},
    supports::Vector{Int64},
    utilities::Vector{Float64},
    prefix::Vector{Int64},
    moSet::Dict{Vector{Int64},Vector{Intervall}},
    hueSet::Dict{Vector{Int64},Vector{Intervall}}, # result set
    mtd::Int64,
    min_sup::Int64,
    min_utililty::Float64,
    total_utility::Float64,
    max_repetition::Int64,
    max_gap::Int64)

    l = length(prefix)

    for range in moSet[prefix]
        I = range.stop+1:min(range.start+mtd+1,length(sequence))
        # SES = @view sequence[I] # Set{Int64}()
        for t in I
            moBeta::Intervall = range.start:t
            
            # gap constrained
            if max_gap >= 0 && length(moBeta) > l+1+max_gap
                break
            end

            if supports[sequence[t]] < min_sup
                continue
            end

            beta = Vector{Int64}(l+1)
            beta[1:l] = prefix
            beta[end] = sequence[t] # for e in SES_t

            if max_repetition >= 0
                c = 0
                for e in beta
                    if e == sequence[t]
                        c += 1
                    end
                end
                if c-1 > max_repetition
                    break
                end
            end

            if !haskey(moSet, beta)
                moSet[beta] = Int64[]
            end

            # M = { mo | if is mo subset of moBeta }
            M = Vector{Intervall}()
            for mo in moSet[beta]
                if mo.start >= moBeta.start && mo.stop <= moBeta.stop # most time is spend here...
                    push!(M,mo)
                end
            end
            if isempty(M)
                # N = { mo | if moBeta is proper subset of mo }
                N = Vector{Intervall}()
                for mo in moSet[beta]
                    if moBeta.start > mo.start && moBeta.stop <= mo.stop
                        push!(N,mo)
                    end
                end
                if !isempty(N)
                    filtered = Vector{Intervall}()
                    for mo in moSet[beta]
                        if !(mo in N)
                            push!(filtered,mo)
                        end
                    end
                    moSet[beta] = filtered
                    push!(moSet[beta], moBeta)
                else
                    if all(r -> r.stop <= moBeta.start, moSet[beta]) # NOTE: strange that M,N generates false positives
                        push!(moSet[beta], moBeta)
                    
                        # for beta in betaSet ...
                        if support(moSet, beta) >= min_sup && ewu(total_utility, utilities, beta, moSet) >= min_utililty
                            if relative_utility(total_utility, utilities, beta) >= min_utililty
                                hueSet[beta] = moSet[beta]
                            end
                
                            # TSpan condition...
                            # if IESC(α, SES) ≥ min utility then, ...
                            if support(moSet, prefix) >= min_sup && iesc(total_utility, utilities, prefix, Set{Int64}(sequence[I])) >= min_utililty
                                s_concatenation!(
                                    sequence,
                                    supports,
                                    utilities,
                                    beta,
                                    moSet,
                                    hueSet,
                                    mtd,
                                    min_sup,
                                    min_utililty,
                                    total_utility,
                                    max_repetition,
                                    max_gap)
                            end
                        end
                    end
                end
            end
        end
    end
end


function min_t_span!(
    sequence::Vector{Int64},
    utilities::Vector{Float64},
    hueSet::Dict{Vector{Int64},Vector{Intervall}}, # result set
    mtd::Int64 = 0,
    min_sup::Int64 = 1,
    min_utililty::Float64 = 0.0,
    max_repetition::Int64 = -1,
    max_gap::Int64 = -1;
    prefixes::Union{Symbol,Vector{Int64}} = :all,
    verbose::Bool = false)

    if max_gap > mtd
        warn("max_gap > max_time_duration has no effect.")
    end

    vertical::Dict{Int,Vector{Int64}} = Index.invert(sequence)
    k = maximum(keys(vertical))
    supports::Vector{Int64} = fill(0,k)
    for (k,v) in vertical
        supports[k] = length(v)
    end
    vertical = filter((k,v)->length(v) >= min_support, vertical)
    moSet::Dict{Vector{Int64},Vector{Intervall}} = Dict(map(kv -> [kv[1]] => map(v -> v:v, kv[2]), collect(vertical)))
    # hueSet::Dict{Vector{Int64},Vector{Intervall}} = Dict{Vector{Int64},Vector{Intervall}}()
    
    tu = total_utility(sequence, utilities)

    # ru = tu / length(sequence)
    # ru = (ru / length(sequence))^2.5
    # utilitly_correction = length(sequence) / (min(max_duration+1, length(sequence)))
    # min_utililty = 0.6

    if prefixes == :all
        prefixes = deepcopy(sort(collect(keys(moSet)), by=x->x[1]))
        if verbose
            @show prefixes
        end
    end

    for prefix in prefixes
        if verbose
            println()
            @show prefix
            info("sup:  ", support(moSet, prefix))
            info("iesc: ", iesc(tu, utilities, prefix, prefix))
            info("ewu:  ", ewu(tu, utilities, prefix, moSet))
            info("ru:   ", relative_utility(tu, utilities, prefix))
            info("u:    ", utility(utilities, prefix))
            info("tu:   ", tu)
        end
        # if support(moSet, prefix) >= min_sup && iesc(tu, utilities, prefix, prefix) >= min_utililty
        if support(moSet, prefix) >= min_sup && ewu(tu, utilities, prefix, moSet) >= min_utililty
            if verbose
                @time s_concatenation!(
                    sequence,
                    supports,
                    utilities,
                    prefix,
                    moSet,
                    hueSet,
                    mtd,
                    min_sup,
                    min_utililty,
                    tu,
                    max_repetition,
                    max_gap)
            else
                s_concatenation!(
                    sequence,
                    supports,
                    utilities,
                    prefix,
                    moSet,
                    hueSet,
                    mtd,
                    min_sup,
                    min_utililty,
                    tu,
                    max_repetition,
                    max_gap)
            end
            
        end
    end

    if verbose
        @show length(moSet)
        @show length(hueSet)
    end

    hueSet
end


max_duration = 0
min_support  = 1
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

# data = readdlm("data/embedding/playground/2018-07-25_51750_assignments_and_reconstruction_error.csv")
# min_utililty = 8.005383703975682e-5
# min_utililty = 0.000038764
# min_utililty = 0.00004945573
# min_utililty = 0.00005      # max_duration:10
# min_utililty = 0.00005308   # max_duration:20
# min_utililty = 7.468059462914433e-5

# data = readdlm("data/embedding/playground/2018-07-28_6073_assignments_and_reconstruction_error.csv")
# min_utililty = 3.3399087787414806e-5
# min_utililty = 0.0

# sequence = map(n->convert(Int64,n), data[:,1])
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


# utilities = rand(maximum(sequence))
# utilities = fill(1.0, maximum(sequence))

hueSet = Dict{Vector{Int64},Vector{Intervall}}()

using ProfileView

Profile.clear()
ts = Vector{Tuple{Vector{Int},Float64,Base.GC_Diff}}()
@show "total"
@profile begin    
    @time min_t_span!(
        sequence,       # ES - event sequence
        utilities,      # external utilities per event
        hueSet,         # results
        max_duration,   # maximal time duration
        min_support,    # absolute minumum support
        min_utililty,   # min_utililty
        max_repetition, # maximum repetitions for each event
        max_gap;        # maximal gap
        verbose = true)
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

#sort(collect(moSet), by=kv->length(kv[1]), rev=false)
sort(collect(hueSet), by=kv->(length(kv[2]),length(kv[1])), rev=false)

# hueSet[[1,2,5]]         # sup:2
# assert(length(hueSet[[1, 2, 5]]) == 2)

# hueSet[[5,5]]           # sup:3
# assert(length(hueSet[[5, 5]]) == 3)

# hueSet[[1, 2, 3, 1, 2]] # sup:1 -overlapping candidate
# assert(length(hueSet[[1, 2, 3, 1, 2]]) == 1)

hueSet