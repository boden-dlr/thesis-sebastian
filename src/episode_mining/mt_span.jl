using LogClustering: Index

using LogClustering.EpisodeMining: support, relative_support
using LogClustering.EpisodeMining: utility, relative_utility, total_utility
using LogClustering.EpisodeMining: ewu, iesc

Intervall = UnitRange{Int64}

function s_concatenation!(
    sequence::Vector{Int64},
    supports::Vector{Int64},
    utilities::Vector{Float64},
    prefix::Vector{Int64},
    moSet::Dict{Vector{Int64},Vector{Intervall}},
    hueSet::Dict{Vector{Int64},Vector{Intervall}}, # result set
    max_time_duration::Int64,
    min_sup::Int64,
    min_utililty::Float64,
    total_utility::Float64,
    max_repetition::Int64,
    max_gap::Int64)

    l = length(prefix)

    for range in moSet[prefix]
        I = range.stop+1:min(range.start+max_time_duration+1,length(sequence))
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

            beta = Vector{Int64}(undef, l+1)
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

            # M = { mo | if mo is subset of moBeta }
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
                    if moBeta.start > mo.start && moBeta.stop <= mo.stop && mo.stop <= moBeta.start # last condition is to avoid false positives
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
                    # if all(r -> r.stop <= moBeta.start, moSet[beta]) # NOTE: strange that M,N generates false positives
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
                                max_time_duration,
                                min_sup,
                                min_utililty,
                                total_utility,
                                max_repetition,
                                max_gap)
                        end
                    end
                    # end
                end
            end
        end
    end
end


function mt_span(
    sequence::Vector{Int64},
    utilities::Vector{Float64},
    max_time_duration::Int64 = 0, # mtd
    min_sup::Int64 = 1,
    min_utililty::Float64 = 0.0,
    max_repetition::Int64 = -1,
    max_gap::Int64 = -1;
    prefixes::Union{Symbol,Vector{Vector{Int64}}} = :all,
    verbose::Bool = false,
    parallel::Bool = false)

    if parallel
        warn(
""" Multi-Threading in Julia is still experimental.

    There could be omitted prefixes due to excecution errors.

    Make sure to `set` (Windows) `export` (Mac/Linux) the number of
    threads (number of virtual cores) for Julia in the OS environment.

    Example (Mac/Linux):

        `export JULIA_NUM_THREADS=4`
    
""")
    end

    if max_gap > max_time_duration
        warn("max_gap > max_time_duration has no effect.")
    end

    vertical::Dict{Int,Vector{Int64}} = Index.invert(sequence)
    k = maximum(keys(vertical))
    supports::Vector{Int64} = fill(0,k)
    for (k,v) in vertical
        supports[k] = length(v)
    end
    vertical = filter(kv->length(kv[2]) >= min_sup, vertical)
    moSet::Dict{Vector{Int64},Vector{Intervall}} = Dict(map(kv -> [kv[1]] => map(v -> v:v, kv[2]), collect(vertical)))
    hueSet::Dict{Vector{Int64},Vector{Intervall}} = Dict{Vector{Int64},Vector{Intervall}}()

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

    if !parallel
        for i = 1:length(prefixes)
            prefix = prefixes[i]

            if verbose
                println()
                info("prefix: ", prefix )
                info("sup:    ", support(moSet, prefix))
                info("iesc:   ", iesc(tu, utilities, prefix, prefix))
                info("ewu:    ", ewu(tu, utilities, prefix, moSet))
                info("ru:     ", relative_utility(tu, utilities, prefix))
                info("u:      ", utility(utilities, prefix))
                info("tu:     ", tu)
            end

            if support(moSet, prefix) >= min_sup && iesc(tu, utilities, prefix, prefix) >= min_utililty
                s_concatenation!(
                    sequence,
                    supports,
                    utilities,
                    prefix,
                    moSet,
                    hueSet,
                    max_time_duration,
                    min_sup,
                    min_utililty,
                    tu,
                    max_repetition,
                    max_gap)
            end
        end
    else
        Threads.@threads for i = 1:length(prefixes)
            prefix = prefixes[i]
            if support(moSet, prefix) >= min_sup && iesc(tu, utilities, prefix, prefix) >= min_utililty
                s_concatenation!(
                    sequence,
                    supports,
                    utilities,
                    prefix,
                    moSet,
                    hueSet,
                    max_time_duration,
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

    moSet, hueSet
end
