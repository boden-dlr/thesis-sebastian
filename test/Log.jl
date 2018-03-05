using Base.Test
using LogClustering.Log

# test with some dummy data
text = [
    string(randstring()),
    string(randstring()),
    string(randstring()),
    string(randstring()),
    string(randstring()),
    string(randstring()),
]

result = Log.split_overlapping(text, r"this text will never be found")
assert(result.prefix == result.suffix)
assert(result.prefix.content == text)
assert(result.prefix.content == text)
assert(length(result.prefix.content) == 6)
assert(length(result.suffix.content) == 6)

# test: find an ID by a given selector
text = [
    "prefix",
    "prefix",
    "prefix",
    string(randstring(), " Marker 'a' ", randstring()),
    string(randstring(), " Marker 'b' ", randstring()),
    string(randstring(), " marker 'a' ", randstring()),
    string(randstring(), " marker 'b' ", randstring()),
    string(randstring(), " marker 'c' ", randstring()),
    string(randstring(), " Marker 'c' ", randstring()),
    "suffix",
    "suffix",
    "suffix",
    "suffix",
]

result = Log.split_overlapping(text, r"Marker \'(.*?)\'"i)
expected = Dict(
    "a" => Log.Occurence(4,6,text[4:6]),
    "b" => Log.Occurence(5,7,text[5:7]),
    "c" => Log.Occurence(8,9,text[8:9]),
)
assert(result.splitted == expected)
assert(result.prefix.content == ["prefix","prefix","prefix"])
assert(result.suffix.content == ["suffix","suffix","suffix","suffix"])
