module Sort

function Base.isless(as::Array{N,1}, bs::Array{N,1}) where {N<:Number}
    A = length(as)
    B = length(bs)
    for i = 1:min(A,B)
        if as[i] < bs[i]
            return true
        elseif as[i] > bs[i]
            return false
        end
    end
    if A < B
        return true
    else
        return false
    end
end

end # module Sort

# using Test
# @assert isless([],[]) == false
# @assert isless([1],[1]) == false
# @assert isless([1],[2]) == true
# @assert isless([1],[1,2]) == true
