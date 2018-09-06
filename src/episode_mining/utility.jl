
#
#  MS-Span utilities
#

function random_utility(e)
    rand()
end

"""
    This utility function weights an episode by the occurence of the
    most valuable event in the current episode.
"""
function local_utility(utilities, episode)
    u_sum = 0
    local_max = 0
    for e in episode
        u = utilities[e]
        u_sum += u
        if u > local_max
            local_max = u
        end
    end
    u_sum / (length(episode) * local_max)
end


function external_utility(utilities, total_utility, episode)
    u_sum = 0
    for e in episode
        u_sum += utilities[e]
    end
    u_sum / total_utility
end


function avg_utility(utilities, total_utility, total_length, episode)
    u_sum = 0
    for e in episode
        u_sum += utilities[e]
    end
    # (u_sum / length(episode) * total_utility / len) / total_utility
    min(1.0, (u_sum / length(episode) / total_length))
end

#
# MT-Span utilities
#

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
