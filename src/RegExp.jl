module RegExp

using LogClustering.Sequence: flatmap
using DataStructures


function escape(s::AbstractString)
    positions = map(
        substr->substr.offset,
        matchall(r"[-\/\\^$*+?.()|\[\]{}]", s))
    
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


function infer(set::Array{Array{String,1},1};
    groups              = true, # infer optional groups
    groups_optional     = false,
    escape_input        = true,
    anchor_start        = false,
    anchor_end          = false,
    insert_placeholder  = false,
    placeholder         = "\\s",
    quantifier_optional = "*?",
    quantifier_required = "+?",
    replacements::Union{Nothing,Dict{String,String}} = nothing)::Regex

    set = deepcopy(set)

    if escape_input || replacements != nothing
        for line in set
            for i in 1:length(line)
                if escape_input
                    line[i] = RegExp.escape(line[i])
                end
                if replacements != nothing
                    for (key,value) in replacements
                        line[i] = replace(line[i], key, value)
                    end
                end
            end
        end
    end

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

    # timestamp = "[\\d\\-]{10,10}\\ [\\d\\:\\,]{12,12}"
    # seperator = "[^\\p{L}]"
    # seperator = "."
    pattern = ""
    for (f, fix) in enumerate(fixpoints)
        fix_pattern = commons_last[fix]
        if insert_placeholder
            fix_pattern = string(fix_pattern, placeholder, quantifier_required)
        end

        if f == 1 #first
            if fix == 1
                pattern = string(pattern, fix_pattern)
            else
                # pattern = string(pattern, "(?:.+",seperator,"+?){1,", fix-1 , "}", fix_pattern)
                if insert_placeholder
                    pattern = string(pattern, placeholder, quantifier_optional, fix_pattern)
                else
                    pattern = string(pattern, fix_pattern)
                end
            end
        elseif f == length(fixpoints) # last
            # @show fix, last, commons_last[fix]
            if fix == shortest
                # pattern = string(pattern, "(?:", commons_last[fix], ")\$")
                if insert_placeholder
                    pattern = string(pattern, commons_last[fix], placeholder, quantifier_optional)
                else
                    pattern = string(pattern, commons_last[fix])
                end
            else
                # pattern = string(pattern, fix_pattern, "(?:.+",seperator,"*?){1,", last-fix, "}\$")
                if insert_placeholder
                    pattern = string(pattern, fix_pattern, placeholder, quantifier_optional)
                else
                    pattern = string(pattern, fix_pattern)
                end
            end
        else # in-between
            previous = fixpoints[f-1]
            if previous == fix-1 # continuous
                pattern = string(pattern, fix_pattern)
            else
                if groups
                    specs = ""
                    rng = previous+1:fix-1
                    for r in rng
                        # specs = string("(?:", join(collect(Set(flatmap(identity, collect(collect(inverted[r]) for r in rng)))),"|"), "){1,1}")
                        specs = string("(?:", join(collect(inverted[r]),"|"), ")") #{1,1}
                        # @show specs
                    end
                    # pattern = string(pattern, seperator, "*?", specs, seperator, "*?", fix_pattern)
                    if insert_placeholder
                        pattern = string(pattern, specs, placeholder, quantifier_optional, fix_pattern)
                    else
                        pattern = string(pattern, specs, fix_pattern)
                    end
                else
                    # @show [inverted[r] for r in rng]
                    # pattern = string(pattern, "(?:.+",seperator,"+?){1,", fix-1 , "}", fix_pattern)
                    if insert_placeholder
                        pattern = string(pattern, placeholder, quantifier_optional, fix_pattern)
                    else
                        pattern = string(pattern, fix_pattern)
                    end
                end
            end
        end
    end

    if groups
        specs = ""
        rng = fixpoints[end]+1:longest
        for r in rng
            if r > shortest
                if groups_optional
                    specs = string("(?:", join(collect(inverted[r]),"|"), ")?") #{0,1}
                else
                    specs = ""
                end
            else
                specs = string("(?:", join(collect(inverted[r]),"|"), ")")  #{1,1}
            end
            if insert_placeholder
                pattern = string(pattern, specs, placeholder, quantifier_optional)
            else
                pattern = string(pattern, specs)
            end
        end
    end
    
    if anchor_start
        if insert_placeholder
            pattern = string('^', placeholder, quantifier_optional, pattern)
        else
            pattern = string('^', pattern)
        end
    end
    if anchor_end
        pattern = string(pattern, '$')
    end

    Regex(pattern)
end

end # module RegExp
