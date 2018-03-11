module Sequence

export rows, cols, flatmap

function ngram(s, N::Int=2)
    grams = [s[i:i+N-1] for i = 1:(length(s)-N+1)]
    grams
end

"""
    flatmap(A->Array{B}, Array{A}) -> Array{B}

Builds a new collection by applying a function to all 
elements of this array and using the elements of the 
resulting collections. [1]

Flattens a two-dimensional array (Array{Array}) by 
concatenating all its rows into a single array. [2]

# Example
```jldoctest
julia> A = [[1], [2,2], [3,3,3]]
3-element Array{Array{Int64,1},1}:
 [1]
 [2, 2]
 [3, 3, 3]

julia> flatmap(identity, A)
6-element Array{Int64,1}:
 1
 2
 2
 3
 3
 3

julia> flatmap(e->e.^2, A)
6-element Array{Int64,1}:
 1
 4
 4
 9
 9
 9
```

[1]: http://www.scala-lang.org/api/2.12.4/scala/Array.html#flatMap[B](f:A=%3Escala.collection.GenTraversableOnce[B]):Array[B]
[2]: http://www.scala-lang.org/api/2.12.4/scala/Array.html#flatten[U](implicitasTrav:T=%3ETraversable[U],implicitm:scala.reflect.ClassTag[U]):Array[U]

"""
function flatmap(f::Function, A::Array)

    mapped = map(f, A)
    
    ts = eltype(mapped).parameters
    t = eltype(eltype(mapped))
    M = length(mapped)
    T = length(ts)

    flattened = Array{t}(M*T)

    k = 1
    for (i,l) in enumerate(mapped)
        for (j,elem) in enumerate(l)
            flattened[k] = elem
            k += 1
        end
    end

    flattened
end

"""
    rows(matrix::Matrix{T}) -> iterator::Array{T}

Yields the rows of a matrix as arrays.

One has to consume the items of the iterator or 
collect the rows to build an array of array.

# Example
```jldoctest
julia> A = rand(1:200, 5, 10)
5×10 Array{Int64,2}:
 137  122  151  164   39   89   61  114   29  191
 190  106   87   22  119    8    4   42  197   40
  49   36   88   70   61  173   70  199   18   85
  13  120  191  140   87   44  164  168   90  138
 110   42   87   58  103   44  153  121  106   40

julia> rs = collect(rows(A))
5-element Array{Array{Int64,1},1}:
 [137, 122, 151, 164, 39, 89, 61, 114, 29, 191]
 [190, 106, 87, 22, 119, 8, 4, 42, 197, 40]
 [49, 36, 88, 70, 61, 173, 70, 199, 18, 85]
 [13, 120, 191, 140, 87, 44, 164, 168, 90, 138]
 [110, 42, 87, 58, 103, 44, 153, 121, 106, 40]
```
"""
function rows(A::Matrix)
    T = typeof(A[1,:])
    Channel(ctype=T) do channel
        for r_i in 1:size(A)[1]
            push!(channel, A[r_i,:])
        end
    end
end

"""
    cols(matrix)

Yields the columns of a matrix `A`.

# Example
```jldoctest
julia> A = rand(1:200, 5, 10)
5×10 Array{Int64,2}:
 137  122  151  164   39   89   61  114   29  191
 190  106   87   22  119    8    4   42  197   40
  49   36   88   70   61  173   70  199   18   85
  13  120  191  140   87   44  164  168   90  138
 110   42   87   58  103   44  153  121  106   40

julia> cs = collect(cols(A))
10-element Array{Array{Int64,1},1}:
 [137, 190, 49, 13, 110]
 [122, 106, 36, 120, 42]
 [151, 87, 88, 191, 87]
 [164, 22, 70, 140, 58]
 [39, 119, 61, 87, 103]
 [89, 8, 173, 44, 44]
 [61, 4, 70, 164, 153]
 [114, 42, 199, 168, 121]
 [29, 197, 18, 90, 106]
 [191, 40, 85, 138, 40]
```
"""
function cols(A::Matrix)
    T = typeof(A[:,1])
    Channel(ctype=T) do channel
        for c_i in 1:size(A)[2]
            push!(channel, A[:,c_i])
        end
    end
end

"""
    convert_to_prefixspan(data::Array{Array})

Convert data into the SPMF prefix format for sequential pattern mining.

# Example
```jldoctest
julia> data = [
           [114, 154, 65, 144, 131],
           [37, 164, 182, 88, 171],
           [158, 84, 56, 192, 148]
       ]
3-element Array{Array{Int64,1},1}:
[114, 154, 65, 144, 131]
[37, 164, 182, 88, 171] 
[158, 84, 56, 192, 148]

julia> formatted = Sequence.convert_to_prefixspan(data)
3-element Array{Array{Int64,1},1}:
 [114, -1, 154, -1, 65, -1, 144, -1, 131, -1, -2]
 [37, -1, 164, -1, 182, -1, 88, -1, 171, -1, -2]
 [158, -1, 84, -1, 56, -1, 192, -1, 148, -1, -2]
```
"""
function convert_to_prefixspan(data)
    seqs = map(
        seq -> flatmap(
            elem -> vcat(elem, [-1]),
            seq),
        data)
    
    map(seq -> vcat(seq, [-2]), seqs)
end

end # module Sequence
