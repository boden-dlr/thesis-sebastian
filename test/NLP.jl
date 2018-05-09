using Base.Test
using LogClustering.NLP
using DataStructures

text = [
    "This is my first line",
    "And this is my second line in the sequence of",
    "this glorious example text",
]

#
# Test 1 - default
#
tokenized, wordcount = NLP.tokenize(text)

tokenized_expected = Array{String,1}[
    String["This", "is", "my", "first", "line"],
    String["And", "this", "is", "my", "second", "line", "in", "the", "sequence", "of"],
    String["this", "glorious", "example", "text"]
    ]
assert(tokenized == tokenized_expected)

wordcount_expected = DataStructures.OrderedDict(
    "is"       => 2,
    "my"       => 2,
    "this"     => 2,
    "line"     => 2,
    "glorious" => 1,
    "in"       => 1,
    "second"   => 1,
    "the"      => 1,
    "sequence" => 1,
    "example"  => 1,
    "first"    => 1,
    "of"       => 1,
    "This"     => 1,
    "text"     => 1,
    "And"      => 1,
)
assert(wordcount == wordcount_expected)

#
# Test 2 - limit
#
tokenized, wordcount = NLP.tokenize(text, limit = Nullable(1))

tokenized_expected = Array{String,1}[
    String["This", "is", "my", "first", "line"],
    ]
assert(tokenized == tokenized_expected)

wordcount_expected = DataStructures.OrderedDict(
    "This"     => 1,
    "is"       => 1,
    "my"       => 1,
    "first"    => 1,
    "line"     => 1,
)
assert(wordcount == wordcount_expected)

#
# Test 3 - splitby
#
tokenized, wordcount = NLP.tokenize(text, splitby = r"line")

tokenized_expected = Array{String,1}[
    String["This is my first "], 
    String["And this is my second ", " in the sequence of"], 
    String["this glorious example text"]
]
assert(tokenized == tokenized_expected)

wordcount_expected = DataStructures.OrderedDict(
    "This is my first "          => 1,
    "And this is my second "     => 1,
    " in the sequence of"        => 1,
    "this glorious example text" => 1,
)
assert(wordcount == wordcount_expected)

#
# Test 4 - replacements
#
replacements = [
    (r"line", "LINE")
]

tokenized, wordcount = NLP.tokenize(text, replacements = replacements)
tokenized_expected = Array{String,1}[
    String["This", "is", "my", "first", "LINE"],
    String["And", "this", "is", "my", "second", "LINE", "in", "the", "sequence", "of"],
    String["this", "glorious", "example", "text"]
    ]
assert(tokenized == tokenized_expected)

wordcount_expected = DataStructures.OrderedDict(
    "is"       => 2,
    "my"       => 2,
    "this"     => 2,
    "LINE"     => 2,
    "glorious" => 1,
    "in"       => 1,
    "second"   => 1,
    "the"      => 1,
    "sequence" => 1,
    "example"  => 1,
    "first"    => 1,
    "of"       => 1,
    "This"     => 1,
    "text"     => 1,
    "And"      => 1,
)
assert(wordcount == wordcount_expected)

#
# Test 5 - lowercase
#
tokenized, wordcount = NLP.tokenize(text, lower = true)
tokenized_expected = Array{String,1}[
    String["this", "is", "my", "first", "line"],
    String["and", "this", "is", "my", "second", "line", "in", "the", "sequence", "of"],
    String["this", "glorious", "example", "text"]
    ]
assert(tokenized == tokenized_expected)

wordcount_expected = DataStructures.OrderedDict(
    "this"     => 3,
    "is"       => 2,
    "my"       => 2,
    "line"     => 2,
    "glorious" => 1,
    "in"       => 1,
    "second"   => 1,
    "the"      => 1,
    "sequence" => 1,
    "example"  => 1,
    "first"    => 1,
    "of"       => 1,
    "text"     => 1,
    "and"      => 1,
)
assert(wordcount == wordcount_expected)

# tf:       Term Frequency
# idf:      Inverse Document Frequency
# tf-idf:   Term Frequency * Inverse Document Frequency

using Base.Test
using LogClustering.NLP

corpus = map(c -> readlines("data/datasets/test/$c.txt"), 1:4)
# read lines
corpus = map(doc -> map(line -> lowercase(line), doc), corpus)
# split and filter by whitespaces und non alphabetic
corpus = map(doc -> map(line -> split(line, r"\s+|[^a-z0-9\']+"i), doc), corpus)
# convert SubStrings to simple Strings
corpus = map(doc -> map(line -> map(term -> convert(String, term), line), doc), corpus)
# filter emptt terms
corpus = map(doc -> map(line -> filter(term -> length(term) > 0, line), doc), corpus)
assert(typeof(corpus) == NLP.Corpus)


@testset "get unique terms" begin

    @testset "of a document" begin
        terms = NLP.terms(corpus[1])
        @test typeof(terms) == NLP.Terms
        @test length(terms) == 67

        terms = NLP.terms(corpus[2])
        @test typeof(terms) == NLP.Terms
        @test length(terms) == 112

        terms = NLP.terms(corpus[3])
        @test typeof(terms) == NLP.Terms
        @test length(terms) == 80

        terms = NLP.terms(corpus[4])
        @test typeof(terms) == NLP.Terms
        @test length(terms) == 90
    end

    @testset "of the whole corpus" begin
        terms = NLP.terms(corpus)
        @test typeof(terms) == NLP.Terms
        @test length(terms) <= 67 + 112 + 80 + 90
        @test length(terms) == 264
    end
    
end

@testset "term frequencies for a document" begin
    
    doc = corpus[1]
    terms = NLP.terms(doc)
    wc = NLP.count_terms(doc, terms=terms)

    @testset "binary" begin
        direct = NLP.binary("lorem", doc, terms=terms)
        indirect = NLP.term_frequency("lorem", doc, mode=:binary, terms=terms)
        @test typeof(direct) == Int64
        @test typeof(indirect) == Int64
        @test direct == indirect
    end

    @testset "binary without keyword arguments" begin
        @test_warn "The unique terms (`::Terms`) of the document should be provided." begin
            direct = NLP.binary("lorem", doc)
            indirect = NLP.term_frequency("lorem", doc, mode=:binary)
            @test typeof(direct) == Int64
            @test typeof(indirect) == Int64
            @test direct == indirect
        end
    end
 
    @testset "raw count" begin
        direct = NLP.count_terms(doc, terms=terms)
        indirect = NLP.term_frequency("lorem", doc, mode=:count, terms=terms, counts=wc)
        @test typeof(direct) == NLP.TermCount
        @test typeof(indirect) == Int64
        @test direct["lorem"] == indirect
    end

    @testset "raw count without keyword arguments" begin
        warnings = [
            "The unique terms (`::Terms`) of the document should be provided.",
            "The count of terms dictionary (`::TermCount`) in the document should provided."
        ]
        @test_warn warnings begin
            direct = NLP.count_terms(doc)
            indirect = NLP.term_frequency("lorem", doc, mode=:count)
            @test typeof(direct) == NLP.TermCount
            @test typeof(indirect) == Int64
            @test direct["lorem"] == indirect
        end
    end

    @testset ":term_frequency" begin
        tf = NLP.term_frequency("lorem", doc, mode=:term_frequency, terms=terms, counts=wc)
        @test typeof(tf) == Float64
        @test tf ≈ 0.07462686567164178
        @test tf ≈ wc["lorem"] / length(wc)
    end

    @testset ":double_normalized" begin
        dn = NLP.term_frequency("lorem", doc, mode=:double_normalized, terms=terms, counts=wc)
        @test typeof(dn) == Float64
        @test dn ≈ 0.5 + 0.5 * (wc["lorem"] / maximum(values(wc)))
    end

end

wcs = NLP.count_terms(corpus)

tfs = NLP.TermFrequencies()
for (i,doc) in enumerate(corpus)
    wc = wcs[i]
    # max = convert(Float64, maximum(values(wc)))
    terms = NLP.terms(doc)
    ts = collect(keys(wc))
    push!(tfs, DataStructures.OrderedDict(
            map(term -> 
                term => NLP.term_frequency(term, doc, terms=terms, counts=wc),
                ts)))
end
tfs


terms = NLP.unique_terms(wcs)
occs = NLP.Dict(map(term -> term => convert(Int64, NLP.count_occurences(term, wcs)), terms))
N = length(corpus)

idf = NLP.Dict(map(term -> term => NLP.inverse_document_frequency(term, N, occs[term]), terms))
@show minimum(values(idf)), maximum(values(idf))

tf_idfs = map(tf -> NLP.Dict{String, Float64}(
    map(term -> 
        if haskey(tf, term)
            # @show term, tf[term], idf[term], tf[term] * idf[term]
            term => tf[term] * idf[term]
        else
            term => 0.0
        end, terms)), tfs)
map(doc-> maximum(values(doc)),tf_idfs)
map(doc-> minimum(values(doc)),tf_idfs)

NLP.naive_tf_idf("typesetting", corpus[1], corpus)
