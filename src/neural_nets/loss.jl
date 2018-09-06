
"""
    moves data to the "border" for given pivot element.

    The border is the upper and lower nearest integer of the pivot element.

    xs:     input data
    pivot:  decision border (default: 0)

    Example:
    ```julia
    julia> repel([0.7, 0.3, 0.0, -0.3, -0.7])
    5-element Array{Float64,1}:
     1.0
     1.0
     0.0
    -1.0
    -1.0
    ```
"""
function repel!(xs, pivot=0.0)
    for i in eachindex(xs)
        if xs[i] >= pivot
            xs[i] = ceil(xs[i])
        else
            xs[i] = floor(xs[i])
        end
    end
    xs
end
