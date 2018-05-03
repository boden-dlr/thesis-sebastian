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

using LogClustering.NLP

corpus = map(c -> readlines("data/datasets/test/$c.txt"), 1:4)
# read lines
corpus = map(doc -> map(line -> lowercase(line), doc), corpus)
# split and filter by whitespaces und non alphabetic
corpus = map(doc -> map(line -> split(line, r"\s+|[^a-z\']+"i), doc), corpus)
# convert SubStrings to simple Strings
corpus = map(doc -> map(line -> map(term -> convert(String, term), line), doc), corpus)
# filter emptt terms
corpus = map(doc -> map(line -> filter(term -> length(term) > 0, line), doc), corpus)
assert(typeof(corpus) == NLP.Corpus)

tfs = NLP.TermFrequencies()
for doc in corpus
    wc = NLP.count_words(doc)
    max = convert(Float64, maximum(values(wc)))
    terms = collect(keys(wc))
    push!(tfs, DataStructures.OrderedDict(
            map(term -> 
                term => NLP.term_frequency(term, doc, wc=wc, max=max),
                terms)))
end
tfs

wcs = NLP.count_words(corpus)
terms = NLP.unique_terms(wcs)
occs = NLP.Dict(map(term -> term => NLP.count_occurences(term, wcs), terms))
N = length(corpus)

idf = NLP.Dict(map(term -> term => NLP.inverse_document_frequency(term, N, occs), terms))

tf_idfs = map(tf -> NLP.Dict{String, Any}(
    map(term -> 
        if haskey(tf, term)
            # @show term, tf[term], idf[term], tf[term] * idf[term]
            term => tf[term] * idf[term]
        else
            term => nothing
        end, terms)), tfs)
