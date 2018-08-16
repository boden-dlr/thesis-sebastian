module RegExp

using LogClustering.Sequence: flatmap
using DataStructures


function escape(s::AbstractString)
    positions = map(
        substr->substr.offset,
        matchall(r"[\^\$\|\-\,\.\:\*\+\?\!\=\\\(\)\[\]\{\}]", s))
    
    splitted = Vector{AbstractString}()
    last = 1
    for pos in positions
        push!(splitted, s[last:pos])
        push!(splitted, string("\\", s[pos+1]))
        last = pos+2
    end
    push!(splitted, s[last:end])

    join(splitted, "")
end


function infer(
    samples::Vector{Vector{String}};
    replacements::Union{Vector{String},Void} = nothing,
    label::Regex = r"%[0-9A-Z\_]*?%",
    asterix::String = ".*?",
    regex = false)

    max = 0
    for s in eachindex(samples)
        sample = samples[s]
        if length(sample) > max
            max = length(sample)
        end
    end  

    function push_word!(set, word)
        if replacements != nothing && any(p->contains(word, p), replacements) #haskey(replacements, word)
            # push!(set, replacements[word].pattern)
            escaped = RegExp.escape(word)
            push!(set, replace(escaped, label, asterix))
        else
            push!(set, RegExp.escape(word))
        end
    end

    groups = OrderedDict{Int64,OrderedSet{String}}()
    origins = OrderedDict{Int64,Vector{Int64}}()
    # TODO: where do the items from all samples have the same succesor group?
    # try not to split into words, but into phrases until a split point occurs.
    for s in eachindex(samples)
        for w in eachindex(samples[s])
            word  = samples[s][w]
            if haskey(groups, w)
                push_word!(groups[w], word)
                push!(origins[w], s)
            else
                groups[w] = OrderedSet{String}()
                push_word!(groups[w], word)
                origins[w] = Vector{Int64}()
                push!(origins[w], s)
            end
        end
    end

    joins = Vector{String}(max)
    for g in eachindex(groups)
        group = collect(groups[g])
        if length(group) > 1
            joins[g] = string("(",join(group,"|"),")")
        else
            joins[g] = join(group)
        end
    end

    joined = strip(join(joins))
    
    if regex
        try return Regex(joined) catch warn(joined) end
    else
        return joined
    end
end


end # module RegExp
