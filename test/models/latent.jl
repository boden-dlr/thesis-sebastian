
"""
    round to the up if higher than `pivot`, round down if lower than `pivot`.
"""
function repel(xs, pivot=0.0)
    for i in eachindex(xs)
        if xs[i] >= pivot
            xs[i] = ceil(xs[i])
        else
            xs[i] = floor(xs[i])
        end
    end
    xs
end
