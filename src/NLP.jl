module NLP

using DataStructures

function is_not_empty(s::String)
    s != ""
end

function is_empty(s::String)
    s == ""
end

Terms = Set{String}
Line = Array{String,1}
Document = Array{Line,1}
Corpus = Array{Document,1}
Dict = DataStructures.OrderedDict

# ::Array{Array{String,1},1}
# function count_words(text)
#     unique_words = reduce(
#         union,
#         Set{String}(),
#         map(line -> unique(line), text))
#     # @show length(unique_words), typeof(unique_words)
#     # @show unique_words
#     word_counts = Dict{String,Int64}(map(word -> (word, 0), unique_words))
#     map(line -> map(word -> word_counts[word] += 1, line), text)

#     DataStructures.OrderedDict(sort(
#             collect(word_counts),
#             by  = (t) -> t[2],
#             rev = true))
# end

TermCount = DataStructures.OrderedDict{String, Int64}
TermCounts = Array{TermCount,1}
@deprecate WordCount TermCount
@deprecate WordCounts TermCounts
TermFrequency = DataStructures.OrderedDict{String, Float64}
TermFrequencies = Array{TermFrequency,1}

warnings = Dict(
    :terms => "The unique terms (`::Terms`) of the document should be provided.",
    :counts => "The count of terms dictionary (`::TermCount`) in the document should provided.",
)

function terms(document::Document)::Terms
    terms = Terms()
    for line in document
        for term in line
            if !(term in terms)
                push!(terms, term)
            end
        end
    end
    terms
end


function terms(corpus::Corpus)::Terms
    terms = Terms()
    for doc in corpus
        union(terms, terms(doc))
    end
    terms
end


function binary(term::String, document::Document;
    terms::Union{Terms,Nothing} = nothing)::Int64
    if terms == nothing
        warn(warnings[:terms])
        terms = NLP.terms(document)
    end
    convert(Int64, haskey(terms.dict, term))
end


function count_terms(document::Document;
    terms::Union{Terms,Nothing} = nothing)::TermCount

    if terms == nothing
        warn(warnings[:terms])
        terms = NLP.terms(document)
    end

    wc = Dict{String,Int64}(map(term -> term => 0, terms))
    for line in document
        for term in line
            wc[term] += 1
        end
    end

    TermCount(sort(
        collect(wc),
        by  = (t) -> t[2],
        rev = true))
end

@deprecate count_words count_terms


function count_term(term::String, document::Document;
    terms::Union{Terms,Nothing} = nothing,
    counts::Union{TermCount,Nothing} = nothing)::Int64

    if counts == nothing
        warn(warnings[:counts])
        counts = NLP.count_terms(document, terms=terms)
    end
    counts[term]
end


function count_terms(corpus::Corpus)::TermCounts
    map(doc -> NLP.count_terms(doc; terms=NLP.terms(doc)), corpus)
end


function count_terms_overall_documents(corpus::Corpus)::TermCount
    wco = TermCount()
    wcs = map(
        doc -> NLP.count(doc, terms=NLP.terms(doc)),
        corpus)

    for wc in wcs
        for (term, c) in collect(wc)
            if haskey(wco, term)
                wco[term] += c
            else
                wco[term] = c
            end
        end
    end
    wco
end


function term_frequency(term::String, counts::TermCount)::Float64
    counts[term] / length(counts)
end


function term_frequency_log_normalized(term::String, counts::TermCount)::Float64
    log(1.0 + counts[term])
end


function maximum_value(d)
    maximum(values(d))
end


function term_frequency_double_normalized(term::String, counts::TermCount, K::Float64 = 0.5)::Float64
    K + (1.0-K) * (counts[term] / maximum_value(counts))
end

"""Calculate the term frequency (default mode :double_normalized).

    mode::Symbol = :double_normalized   term frequency mode

        :binary             ::Int64     0,1     occurance (false, true)
        :count              ::Int64     Z       counts[term]
        :term_frequency     ::Float64   R       counts[term] / length(counts)
        :log_normalized     ::Float64   R       log(1 + counts[term])
        :double_normalized  ::Float64   R       K + (1-K) * (counts[term] / maximum(values(counts)))

    terms::Terms

    counts::TermCount

    K::Float64 = 0.5

"""
function term_frequency(term::String, document::Document;
    mode::Symbol = :double_normalized,
    terms::Union{Terms,Nothing} = nothing,
    counts::Union{TermCount,Nothing} = nothing,
    K::Float64 = 0.5)

    if terms == nothing
        warn(warnings[:terms])
        terms = NLP.terms(document)
    end

    if mode != :binary && counts == nothing
        warn(warnings[:counts])
        counts = NLP.count_terms(document, terms=terms)
    end

    if mode == :binary
        return binary(term, document, terms=terms)
    elseif mode == :count
        return count_term(term, document, terms=terms, counts=counts)
    elseif mode == :term_frequency
        return term_frequency(term, counts)
    elseif mode == :log_normalized
        return term_frequency_log_normalized(term, counts)
    elseif mode == :double_normalized
        return term_frequency_double_normalized(term, counts, K)
    end
end



function naive_term_frequency(term::String, document::Document;
    normalize::Bool = true,
    wc::Union{TermCount, Nothing} = nothing,
    max::Union{Float64, Nothing} = nothing)

    wc == nothing ? wc = count_words(document) : wc
    result::Float64 = wc[term]
    if normalize
        max == nothing ? max = convert(Float64, maximum(values(wc))) : max
        result = result / max
    end
    result
end


function unique_terms(wcs::TermCounts)
    unique(vcat(map(wc -> collect(keys(wc)), wcs)...))
end

function count_occurences(term::String, wcs::TermCounts)
    reduce(+, 0.0, map(wc -> haskey(wc, term), wcs))
end


"""Calculates the idf for given term and corpus

    The corpus is provided as precalculated values for `N` and `n_term`.

    term::String            given term.

    N::Integer              Overall number of documents in the corpus (dataset).

    n_term::Integer         Number of documents in the corpus containing given
                            term.

    mode::Symbol = :idf     idf weighting

        :unary              `1`
        :idf                `log(N / n_term)`
        :smooth             `log(1 + N / n_term)`
        :max                `log(max(terms_in documents) / 1 + n_term)`
        :probabilistic      `log(N - n_term / n_term)`

    divzero::Float64 = 1.0  Avoid division by zero by adding a threshold to the 
                            idf-denominator.
                            Modes `:unary` and `:max` always avoid divison by
                            zero.

    max::Integer            maximal occurance of all terms in the corpus.

        ```julia
        terms = NLP.terms(corpus)
        term_counts = NLP.count_terms(corpus)
        max = maximum(map(term -> 
            convert(Int64, NLP.count_occurences(term, term_counts)),
            terms))
        ```

"""
function inverse_document_frequency(
    term::String,
    N::Integer,
    n_term::Integer;
    mode::Symbol = :idf,
    divzero::Float64 = 0.0,
    max::Union{Integer,Nothing} = N)

    if mode == :unary
        return 1.0
    end
    
    if mode == :idf
        return log(N / (divzero + n_term))
    elseif mode == :smooth
        return log(1.0 + (N / divzero + n_term))
    elseif mode == :max
        if max == nothing
            error("`max` should be provided as keyword argument.")
        end
        return log(max / (1.0 + n_term))
    elseif mode == :probabilistic
        return log((N - n_term) / (divzero + n_term))
    else
        error("unkown mode")
    end
end


function naive_inverse_document_frequency(term::String, corpus::Corpus;
    mode::Symbol = :idf,
    divzero::Float64 = 0.0,
    max::Union{Integer,Nothing} = nothing)
    warn("""Using the naive idf implementation is not recommended.
    Consider using `NLP.inverse_document_frequency` by providing precalculated arguments.""")

    N = length(corpus)
    wcs = NLP.count_terms(corpus)
    terms = NLP.unique_terms(wcs)
    terms_in_docs = NLP.Dict(map(
        term -> term => convert(Int64, NLP.count_occurences(term, wcs)),
        terms))

    NLP.inverse_document_frequency(term, N, terms_in_docs[term]; mode=mode, divzero=divzero, max=max)
end


function naive_tf_idf(term::String, document::Document, corpus::Corpus)
    # tf(t, d) * idf(t, D)
    term_frequency(term, document) * naive_inverse_document_frequency(term, corpus)
end


function tokenize(lines::Array{String};
    limit::Union{Nothing,Int64} = nothing,
    splitby::Regex = r"\s+",
    replacements::Array{Tuple{Regex,String}} = Array{Tuple{Regex,String}}(0),
    lower::Bool = false)

    # lines = readlines(src)
    # @show length(lines)
    lines_filtered = filter(is_not_empty, lines)
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
            is_not_empty,
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
    if limit == nothing
        lines_limited = lines_reduced
    else
        lines_limited = lines_reduced[1:limit.value]
    end

    if lower 
        lines_limited = map((line) -> map((word) -> lowercase(word), line),lines_limited)
    end
    # @show lines_limited
    # @show length(lines_limited), typeof(lines_limited)
    ts = NLP.terms(lines_limited)
    termcount = count_terms(lines_limited, terms=ts)
    # for elem in termcount
    #     @show elem
    # end
    # @show length(termcount), typeof(termcount)

    lines_limited, termcount
end


function split_and_keep_splitter(str::S, pattern::Regex;
    keep_empty=false) where S<:AbstractString

    list::Union{Nothing,Array{S}} = nothing
    
    ms = matchall(pattern, str)
    if isempty(ms)
        if keep_empty
            list = [str]
        else
            str == "" ? list = [] : list = [str]
        end
    else
        list = Vector{S}()        
        splts = map(m->(m.offset+1,m.offset+m.endof),ms)
        n = length(splts)
        for (i,splt) in enumerate(splts)
            current = str[splt[1]:splt[2]]

            if i == 1
                before = str[1:splt[1]-1]
            else
                before = str[splts[i-1][2]+1:splt[1]-1]
            end
                
            if keep_empty
                push!(list, before)
                push!(list, current)
            else
                before  != ""  ? push!(list, before) : nothing
                current != ""  ? push!(list, current) : nothing
            end

            if i == n
                last = str[splt[2]+1:end]
                if keep_empty
                    push!(list, last)
                else
                    last    != "" ? push!(list, last) : nothing
                end
            end
        end
    end
    return list
end


# split_and_keep_splitter("", r"[\w\p{L}]+")
# split_and_keep_splitter("2014-12-02 08:27:33,090 DEBUG - de.rcenvironment.components.cpacs.vampzeroinitializer.common - BundleEvent [unknown:512] - de.rcenvironment.components.cpacs.vampzeroinitializer.common", r"[\w\p{L}\.]+")


end # module NLP
