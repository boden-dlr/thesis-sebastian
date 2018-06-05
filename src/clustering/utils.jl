using Clustering


Assignments = Array{Int64,1}
NestedAssignments = Array{Array{Int64,1},1}


function clustering_to_assignments(C::NestedAssignments)::Assignments
    N = 0
    for c in C
        N += length(c)
    end
    assignments = zeros(Int64,N)
    for (i,c) in enumerate(C)
        for n in c
            assignments[n] = i
        end
    end
    assignments
end


function clustering_to_assignments(C::Array{Clustering.DbscanCluster,1})::Assignments
    N = 0
    for c in C
        N += length(c.core_indices)
        N += length(c.boundary_indices)
    end
    assignments = zeros(Int64,N)
    for (i,c) in enumerate(C)
        for n in c.core_indices
            assignments[n] = i
        end
        for n in c.boundary_indices
            assignments[n] = i
        end
    end
    assignments
end


function assignments_to_clustering(assignments::Assignments)::NestedAssignments
    nested = Vector{Vector{Int64}}()
    for (n, c) in enumerate(assignments)
        if c > length(nested)
            push!(nested, [n])
        else
            push!(nested[c], n)
        end
    end
    nested
end


function soft_to_hard_assignments(weights::Array{Float64,2})::Assignments
    n,k = size(weights)
    assignments = Assignments(n)
    for i in 1:n
        assignments[i] = indmax(weights[i,:])
    end
    assignments
end


# tests
in  = [1,2,2,3,3,3,4,4,4,4]
C = assignments_to_clustering(in)
out = clustering_to_assignments(C)
assert(in == out)


c1 = Clustering.DbscanCluster(2,[1,2],[])
c2 = Clustering.DbscanCluster(2,[3,4,5],[6])
assignments_to_clustering(clustering_to_assignments([c1, c2]))


# soft to hard assignments
m = 3
n = 1000
k = 5

x = rand(m,n)

fuzziness = 2.0
srand(34568)
r = fuzzy_cmeans(x, k, fuzziness)

ass = soft_to_hard_assignments(r.weights)
assignments_to_clustering(ass)
