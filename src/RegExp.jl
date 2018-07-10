module RegExp

using LogClustering.Sequence: flatmap
using DataStructures

function infer(set::Array{Array{String,1},1},
    specific=true,
    seperator=".",
    optional="*?",
    required="+?")::Regex
    commons = Dict{String, Int64}()
    vocabulary = Dict{String,Int64}()
    occurences = Dict{String,Vector{Tuple{Int64,Int64}}}()
    inverted = Dict{Int64,Set{String}}()

    function add_word(word, l, w)
        vocabulary[word] += 1
        push!(occurences[word], (l,w))
        if haskey(inverted, w)
            push!(inverted[w], word)
        else
            inverted[w] = Set{String}()
            push!(inverted[w], word) 
        end
    end

    function init_word(word, l, w)
        vocabulary[word] = 1
        occurences[word] = Vector{Tuple{Int64,Int64}}()
        push!(occurences[word], (l,w))
        # inverted[w] = Set{String}()
        # push!(inverted[w], word)
        if haskey(inverted, w)
            push!(inverted[w], word)
        else
            inverted[w] = Set{String}()
            push!(inverted[w], word) 
        end
    end

    function in_all(word, set)
        minimum(map(line-> count(w-> w == word,line),set))
    end

    for (l,line) in enumerate(set)
        for (w,word) in enumerate(line)
            if length(word) > 0
                if haskey(vocabulary, word)
                    add_word(word, l, w)
                else
                    init_word(word, l, w)
                    occs = in_all(word, set)
                    if occs > 0
                        commons[word] = occs
                    end
                end
            end
        end
    end

    commons_last = Dict{Int64, String}()
    for (word, occs) in commons
        for (_,w) in occurences[word][end-occs+1:end]
            commons_last[w] = word
        end
    end
    commons_last = DataStructures.OrderedDict(sort(collect(commons_last), by=t->t[1]))
    fixpoints = collect(keys(commons_last))
    shortest = minimum(map(line->length(filter(w->length(w)>0,line)), set))
    longest = maximum(map(line->length(filter(w->length(w)>0,line)), set))

    timestamp = "[\\d\\-]{10,10}\\ [\\d\\:\\,]{12,12}"
    # seperator = "[^\\p{L}]"
    # seperator = "."
    pattern = ""
    for (f, fix) in enumerate(fixpoints)
        fix_pattern = string(commons_last[fix], seperator , "+?")
        
        # preprocessing
        if commons_last[fix] == "timestamp"
            fix_pattern = string(timestamp, seperator , "+?")
        end

        if f == 1 #first
            if fix == 1
                pattern = string(pattern, fix_pattern)
            else
                # pattern = string(pattern, "(?:.+",seperator,"+?){1,", fix-1 , "}", fix_pattern)
                pattern = string(pattern, seperator, "*?", fix_pattern)
            end
        elseif f == length(fixpoints) # last
            # @show fix, last, commons_last[fix]
            if fix == shortest
                # pattern = string(pattern, "(?:", commons_last[fix], ")\$")
                pattern = string(pattern, commons_last[fix], seperator, "*?")
            else
                # pattern = string(pattern, fix_pattern, "(?:.+",seperator,"*?){1,", last-fix, "}\$")
                # pattern = string(pattern, fix_pattern, seperator, "*?")
                pattern = string(pattern, fix_pattern)
            end
        else # in-between
            previous = fixpoints[f-1]
            if previous == fix-1 # continuous
                pattern = string(pattern, fix_pattern)
            else
                if specific
                    specs = ""
                    rng = previous+1:fix-1
                    for r in rng
                        # specs = string("(?:", join(collect(Set(flatmap(identity, collect(collect(inverted[r]) for r in rng)))),"|"), "){1,1}")
                        specs = string("(?:", join(collect(inverted[r]),"|"), ")") #{1,1}
                        # @show specs
                        pattern = string(pattern, specs, seperator, "*?")
                    end
                    # pattern = string(pattern, seperator, "*?", specs, seperator, "*?", fix_pattern)
                    # pattern = string(pattern, specs, seperator, "*?", fix_pattern)
                else
                    # @show [inverted[r] for r in rng]
                    # pattern = string(pattern, "(?:.+",seperator,"+?){1,", fix-1 , "}", fix_pattern)
                    # pattern = string(pattern, seperator, "*?", fix_pattern)
                    pattern = string(pattern, fix_pattern)
                end
            end
        end
    end

    if specific
        # specs = ""
        # rng = fixpoints[end]+1:longest
        # elems = collect(Set(flatmap(identity, collect(collect(inverted[r]) for r in rng))))
        # if length(elems) > 0
        #     specs = string("(?:", join(elems,"|"), "){1,1}")
        #     @show specs
        #     pattern = string(pattern, specs, seperator, "*?")
        # end

        specs = ""
        rng = fixpoints[end]+1:longest
        for r in rng
            if r > shortest
                specs = string("(?:", join(collect(inverted[r]),"|"), ")?") #{0,1}
            else
                specs = string("(?:", join(collect(inverted[r]),"|"), ")") #{1,1}
            end
            pattern = string(pattern, specs, seperator, "*?")
        end
    end

    
    if (startswith(pattern, string(seperator, "*?")) || 
        startswith(pattern, string(seperator, "+?")) ||
        startswith(pattern, timestamp))
        pattern = string("^", pattern, "\$")
    else
        pattern = string("^", seperator, "*?", pattern, "\$")
    end

    Regex(pattern)
end

end # module RegExp
