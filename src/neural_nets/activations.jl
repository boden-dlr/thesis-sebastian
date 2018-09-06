using Flux

function clamp_asin(x)
    if x > 1
        return asin(param(1))
    elseif x < -1
        return asin(param(-1))
    else
        return asin(x)
    end
end
