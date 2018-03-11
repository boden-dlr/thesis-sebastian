module Sort

function Base.isless{N<:Number}(as::Array{N,1}, bs::Array{N,1})
    A = length(as)
    B = length(bs)
    for i = 1:min(A,B)
        if as[i] > bs[i]
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