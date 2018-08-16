using DataStructures: OrderedDict

mutable struct Occurence
    occ::Vector{Bool}
    count::Vector{Int}
end

function occurences(doc::Vector{Vector{S}}) where S<:AbstractString
    occs = Dict{String,Occurence}()
    for l in eachindex(doc)
        line = doc[l]
        for w in eachindex(line)
            word = line[w]
            if haskey(occs, word)
                occs[word].occ[l] = true
                occs[word].count[l] += 1
            else
                occs[word] = Occurence(
                    fill(false, length(doc)),
                    fill(0, length(doc)))
                occs[word].occ[l] = true
                occs[word].count[l] = 1
            end
        end
    end
    occs
end

function common_words(occSet::Dict{String,Occurence})
    common = Dict{String,Int}()
    for (word, occs) in occSet
        if all(occs.occ)
            if haskey(common, word)
                common[word] += sum(occs.count)
            else
                common[word] = sum(occs.count)
            end
        end
    end
    sort(common, by=kv->kv[2])
end

function invert(document::Vector{Vector{S}}, by=:line) where S<:AbstractString
    inverted_index = OrderedDict{String,OrderedDict{Int64,Vector{Int64}}}()
    tmp = 0
    for l in eachindex(document)
        line = document[l]
        for w in eachindex(line)
            word = line[w]
            
            # swap
            if by == :word
                tmp = w
                w = l
                l = tmp
            end

            if haskey(inverted_index, word)
                if haskey(inverted_index[word], l)
                    push!(inverted_index[word][l], w)
                else
                    inverted_index[word][l] = Int[w]
                end
            else
                inverted_index[word] = OrderedDict{Int64,Vector{Int64}}()
                inverted_index[word][l] = Int[w]
            end
        end
    end
    inverted_index
end


set = [
    ["Some", "books", "are", "to", "be", "tasted"],
    ["others", "to", "be", "swallowed"],
    ["and", "some", "few", "to", "be", "chewed", "and", "digested"],
    ["to", "be", "or", "not", "to", "be"],
    ["to", "be", "or", "not", "to", "be", "this", "is", "the", "question"],
]

occs = occurences(set)
occs = common_words(occs)
inverted_index = invert(set, :word)

for (word, cnt) in occs
    @show inverted_index[word]
end

froms = fill(1,length(set))
prevs = nothing
@time for current = 1:10
    candidates = Vector{Any}()
    for (word, cnt) in occs
    push!(candidates, map(x-> length(x) >= current ? x[current] : nothing, values(inverted_index[word])))
    end
    candidates
    

    min_candidate = (0,Inf)
    for (c,candidate) in enumerate(candidates)
        for v in candidate
            if v == nothing
                continue
            end
            if v < min_candidate[2]
                min_candidate = (c,v)
            end
        end
    end
    # @show min_candidate

    if min_candidate[1] == 0
        indices = prevs
    else
        indices = candidates[min_candidate[1]]
        prevs = deepcopy(candidates[min_candidate[1]])
    end

    @show indices
    @show froms

    for l in eachindex(set)
        line = set[l]
        if indices[l] != nothing
            if froms[l] < length(line)
                joined = join(line[froms[l]:indices[l]])
                @show "inter", joined
                froms[l] = indices[l]+1
            else
                joined = join(line[froms[l]-1:length(line)])
                @show "last", joined
                froms[l] = length(line)
            end
        elseif froms[l] < length(line)
            joined = join(line[froms[l]:length(line)])
            @show "final", joined
            froms[l] = length(line)
        end
        
    end
    # @show froms

    if all(map(cs->all(c->c == nothing, cs), candidates))
        info("ende")
        break
    end
end
