using LogClustering.NLP
using LogClustering.Index
using DataStructures: OrderedDict, OrderedSet


function count_word_per_line(source::Vector{Vector{String}}, inverted::Dict{String,Vector{Tuple{Int64,Int64}}})
    od = OrderedDict{String, Vector{Int}}()
    for (key, occs) in inverted
        v = fill(0, length(source))
        for (l, _) in occs
            v[l] += 1
        end
        od[key] = v
    end
    od
end

function is_occurring_in_all_lines(counts::OrderedDict{String, Vector{Int}})
    filtered = Vector{String}()
    for (word, cs) in counts
        if all(map(c-> c >= 1 ? true : false, cs))
            push!(filtered, word)
        end
    end
    filtered
end

function mark_fix_words(source::Vector{Vector{String}}, fix::Vector{String})
    map(line-> map(word-> word in fix ? true : false, line), source)
end

function maximum_line_length(source::Vector{Vector{String}})
    m = argmax(map(length, source))
    length(source[m])
end

mutable struct Group
    words::OrderedSet{String}
    quantifier::UnitRange{Int}

    Group() = begin
        new(OrderedSet{String}(), 1:0)
    end
end

function group_until_fix_word_occurs(source, fixed, mlm)
    groups = Vector{Group}()
    for (l,line) in source
        i = 1
        for (w, word) in line
            if fixed[l][w]
                if i <= length(groups)
                    push!(groups[i].words, word)
                else
                    push!(groups, Group())
                    push!(groups[i].words, word)
                end
            else

                # TODO: count until mutable...
                # if i <= length(groups)
                #     start = groups[i].quantifier.start
                #     stop = groups[i].quantifier.stop + 1
                #     push!(groups[i].quantifier, start:stop)
                # else
                #     push!(groups, Group())
                #     push!(groups[i].words, word)
                # end
            end
        end
    end
end

function filter_by_occurence_per_sample(set::Vector{Vector{String}})
    vocab = NLP.count_terms(set)
    inverted = Index.invert(text, collect(keys(vocab)))
    counts = count_word_per_line(set, inverted)
    fix = is_occurring_in_all_lines(counts)
    fix_set = mark_fix_words(set, fix)
    mlm = maximum_line_length(set)

end

# text = [
#     ["%RCE_DATETIME%","DEBUG","-","%URI%","-","ServiceEvent","REGISTERED","-","{%URI%}={%URI%=Parametric","Study,","%URI%=true,","%URI%=%FLOAT%,","%URI%=parametric_study%INT%.png,","%URI%=Evaluation,","%URI%=[%URI%,%URI%.ParametricStudyComponent_Parametric","Study],","%FILE%,","%URI%=%URI%,","%URI%=true,","%FILE%,","%URI%=%URI%,","%URI%=%INT%,","%URI%=Parametric","Study,","%URI%=%URI%,","%URI%=parametric_study%INT%.png,","%FILE%,","%URI%=%INT%}","-","%URI%"],
#     ["%RCE_DATETIME%","DEBUG","-","%URI%","-","ServiceEvent","UNREGISTERING","-","{%URI%}={%URI%=Parametric","Study,","%URI%=true,","%URI%=%FLOAT%,","%URI%=parametric_study%INT%.png,","%URI%=Evaluation,","%URI%=[%URI%,%URI%.ParametricStudyComponent_Parametric","Study],","%FILE%,","%URI%=%URI%,","%URI%=true,","%FILE%,","%URI%=%URI%,","%URI%=%INT%,","%URI%=Parametric","Study,","%URI%=%URI%,","%URI%=parametric_study%INT%.png,","%FILE%,","%URI%=%INT%}","-","%URI%"],
# ]
#
# filter_by_occurence_per_sample(text)
