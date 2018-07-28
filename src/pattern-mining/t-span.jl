using LogClustering: Index

Intervall = UnitRange{Int64}

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
    u = utility(utilities, episode)
    u = u * length(moSet[episode]) / total_utility
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

function s_concatenation!(
    sequence::Vector{Int64},
    utilities::Vector{Float64},
    prefix::Vector{Int64},
    moSet::Dict{Vector{Int64},Vector{Intervall}},
    hueSet::Dict{Vector{Int64},Vector{Intervall}}, # result set
    mtd::Int64,
    min_sup::Int64,
    min_utililty::Float64,
    total_utility::Float64)

    betaSet = Set{Vector{Int64}}()
    l = length(prefix)

    for range in moSet[prefix]
        I = range.stop+1:min(range.start+mtd+1,length(sequence))
        SES = sequence[I]
        for t in I
            # for simple event sequences there is only one event `e`
            # otherwise we need a loop for each event `e` (for all simultaniuos)
            beta = Vector{Int64}(l+1)
            beta[1:l] = prefix
            beta[end] = sequence[t] # event `e` of SES
            if !haskey(moSet, beta)
                moSet[beta] = []
            end
            moBeta = range.start:t
            # M = { mo | if is mo subset of moBeta }
            M = filter(x -> x != nothing, [
                (
                    mo.start >= moBeta.start && mo.stop <= moBeta.stop
                ) ? mo : nothing
                for mo in moSet[beta]])
            if isempty(M)
                # N = { mo | if moBeta is proper subset of mo }
                N = filter(x -> x != nothing, [
                    (
                        moBeta.start > mo.start && moBeta.stop <= mo.stop
                    ) ? mo : nothing
                    for mo in moSet[beta]])
                if !isempty(N)
                    moSet[beta] = filter(r->!(r in N), moSet[beta])
                    push!(moSet[beta], moBeta)
                else
                    if all(r -> r.stop <= moBeta.start, moSet[beta]) # N ???
                        union!(betaSet, Set([beta]))
                        push!(moSet[beta], moBeta)
                    
                        if support(moSet, beta) >= min_sup && ewu(total_utility, utilities, beta, moSet) >= min_utililty
                            if utility(utilities, beta) >= min_utililty
                            # if relative_utility(total_utility, utilities, beta) >= min_utililty
                                hueSet[beta] = moSet[beta] # sort(moSet[beta], by=r->r.start)
                            end
                
                            # TSpan condition...
                            # if IESC(α) ≥ min utility then
                            t_span!(
                                sequence,
                                utilities,
                                beta,
                                moSet,
                                hueSet,
                                mtd,
                                min_sup,
                                min_utililty,
                                total_utility,
                                SES)
                        end
                    end
                end
            end
        end
    end

    # for beta in betaSet
    #     if ewu(total_utility, utilities, beta, moSet) >= min_utililty && support(moSet, beta) >= min_sup
    #         if utility(utilities, beta) >= min_utililty
    #             hueSet[beta] = sort(moSet[beta], by=r->r.start)
    #         end
    #         # TSpan...
    #     end
    # end
end


function t_span!(
    sequence,
    utilities,
    alpha,
    moSet,
    hueSet,
    mtd,
    min_sup,
    min_utililty,
    total_utility,
    SES)


    if support(moSet, alpha) >= min_sup && iesc(total_utility, utilities, alpha, SES) >= min_utililty
        # @show support(moSet, alpha)
        # @show iesc(total_utility, utilities, alpha, SES)
        s_concatenation!(
            sequence,
            utilities,
            alpha,
            moSet,
            hueSet,
            mtd,
            min_sup,
            min_utililty,
            total_utility)
            # no SES
    end
    
end

#                A B C E D G E A B C F E E A B D 
sequence = Int64[1,2,3,5,4,8,5,1,2,3,7,5,5,1,2,4]
#                0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1
#                1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6

utilities = Float64[0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8]
# utilities = fill(1.0, maximum(sequence))

data = readdlm("data/embedding/playground/2018-07-25_assignments_and_reconstruction_error.csv")
sequence = map(n->convert(Int64,n), data[:,1])
utilities = map(n->convert(Float64,n), data[:,2])
# utilities = rand(maximum(sequence))
# utilities = fill(1.0, maximum(sequence))

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

vertical = Index.invert(sequence)
moSet = Dict(map(kv -> [kv[1]] => map(v -> v:v, kv[2]), collect(vertical)))
hueSet = Dict{Vector{Int64},Vector{Intervall}}()
max_duration = 20
min_support  = 5000
min_utililty = 0.000038764
tu = total_utility(sequence, utilities)

# ru = tu / length(sequence)
# ru = (ru / length(sequence))^2.5
# correction term = length(sequence) / (mtd+1)
# min_utililty = 0.6

for prefix in deepcopy(keys(moSet))
    t_span!(
        sequence,     # ES - event sequence
        utilities,    #
        prefix,       # alpha
        moSet,        # moSet
        hueSet,       # results
        max_duration, # maximal time duration
        min_support,  # absolute minumum support
        min_utililty, # min_utililty
        tu,           # total_utility
        prefix)       # initial SES == prefix
                      
end
#sort(collect(moSet), by=kv->length(kv[1]), rev=false)
sort(collect(hueSet), by=kv->(length(kv[2]),length(kv[1])), rev=false)

hueSet
moSet

hueSet[[1,2,5]]
hueSet[[5,5]]
