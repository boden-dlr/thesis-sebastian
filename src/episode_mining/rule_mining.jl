
Intervall = UnitRange{Int64}
MoSet = Dict{Vector{Int64},Vector{Intervall}}

function conf(pab, pa, pb)
    pab / (pa * pb)
end

function mine_high_conf(hueSet::MoSet, moSet::MoSet, confidence::Float64)
    highConf = Vector{Tuple{Vector{Int64},Float64}}()

    for (alpha, occs) in hueSet
        if length(alpha) >= 2
            beta = alpha[1:end-1]
            gamma = alpha[end:end]

            alpha_count = length(moSet[alpha])
            beta_count = length(moSet[beta])
            gamma_count = length(moSet[gamma])

            c = conf(alpha_count, beta_count, gamma_count)

            if c >= confidence
                push!(highConf, (alpha, c))
            end
        end
    end

    highConf
end
