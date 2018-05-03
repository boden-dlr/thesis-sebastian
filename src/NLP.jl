module NLP

using DataStructures

function nonempty(s)
    s != ""
end

function empty(s)
    s == ""
end

Line = Array{String,1}
Document = Array{Line,1}
Corpus = Array{Document,1}
Dict = DataStructures.OrderedDict

# ::Array{Array{String,1},1}
function count_words(text)
    unique_words = reduce(
        union,
        Set{String}(),
        map(line -> unique(line), text))
    # @show length(unique_words), typeof(unique_words)
    # @show unique_words
    word_counts = Dict{String,Int64}(map(word -> (word, 0), unique_words))
    map(line -> map(word -> word_counts[word] += 1, line), text)

    DataStructures.OrderedDict(sort(
            collect(word_counts),
            by  = (t) -> t[2],
            rev = true))
end

WordCount = DataStructures.OrderedDict{String, Int64}
WordCounts = Array{WordCount,1}
TermFrequency = DataStructures.OrderedDict{String, Float64}
TermFrequencies = Array{TermFrequency,1}

function term_frequency(term, document; normalize::Bool = true, wc::Union{WordCount, Void} = nothing, max::Union{Float64, Void} = nothing)
    wc == nothing ? wc = count_words(document) : wc
    result::Float64 = wc[term]
    if normalize
        max == nothing ? max = convert(Float64, maximum(values(wc))) : max
        result = result / max
    end
    result
end

function count_words(corpus::Corpus)::WordCounts
    map(doc -> count_words(doc), corpus)
end

function unique_terms(wcs::WordCounts)
    unique(vcat(map(wc -> collect(keys(wc)), wcs)...))
end

function count_occurences(term::String, wcs::WordCounts)
    reduce(+, 0.0, map(wc -> haskey(wc, term), wcs))
end

function inverse_document_frequency(term::String, N::Int64, count::TermFrequency)
    # N = length(corpus)
    # WCs = WordCount[]
    # for doc in corpus
    #     push!(WCs, count_words(doc))
    # end
    # terms = unique(vcat(map(wc -> collect(keys(wc)), WCs)...))
    # map(term -> term => N / reduce(+, 0.0, map(wc -> haskey(wc, term), WCs)), terms)
    N / count[term]
end


function tf_idf(corpus)
    # tf(t, D) * idf(t)

end


function tokenize(lines::Array{String};
    limit::Nullable{Int64} = Nullable{Int64}(),
    splitby::Regex = r"\s+",
    replacements::Array{Tuple{Regex,String}} = Array{Tuple{Regex,String}}(0),
    lower::Bool = false)

    # lines = readlines(src)
    # @show length(lines)
    lines_filtered = filter(nonempty, lines)
    # @show length(lines_filtered), typeof(lines_filtered)
    # @show lines_filtered

    for repl in replacements
        map!(line ->
            replace(line, repl[1], repl[2]),
            lines_filtered,
            lines_filtered)
    end
    lines_preprocessed = lines_filtered
    # for i = 1:10
    #     @show lines_preprocessed[i]
    # end

    lines_splitted = map(line ->
        filter(
            nonempty,
            map(sub ->
                convert(String,sub),
                split(line, splitby))
            ),
            lines_preprocessed)
    # for i = 1:10
    #     @show lines_splitted[i]
    # end
    lines_reduced = filter(line -> length(line) != 0, lines_splitted)

    # @show length(lines_splitted), typeof(lines_splitted)
    if isnull(limit)
        lines_limited = lines_reduced
    else
        lines_limited = lines_reduced[1:limit.value]
    end

    if lower 
        lines_limited = map((line) -> map((word) -> lowercase(word), line),lines_limited)
    end
    # @show lines_limited
    # @show length(lines_limited), typeof(lines_limited)
    word_count = count_words(lines_limited)
    # for elem in word_count
    #     @show elem
    # end
    # @show length(word_count), typeof(word_count)

    lines_limited, word_count
end

end # module NLP
