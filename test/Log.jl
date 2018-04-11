using Base.Test
using LogClustering.Log
using LogClustering.Sequence

# test with some dummy data
text = [
    string(randstring()),
    string(randstring()),
    string(randstring()),
    string(randstring()),
    string(randstring()),
    string(randstring()),
]

result = Log.segment(text, r"this text can't be found")
assert(result.beginning == result.ending)
assert(length(result.beginning) == 6)
assert(length(result.ending) == 6)

# ------------------------------------------------------------------------------

# test: find an ID by a given selector
text = [
    "preabmle", # 1
    "preabmle", # 2
    "preabmle", # 3
    string(randstring(), " Marker 'a' ", randstring()), # 4
    string(randstring(), " Marker 'b' ", randstring()), # 5
    string(randstring(), " marker 'c' ", randstring()), # 6
    string(randstring(), " marker 'b' ", randstring()), # 7
    string(randstring(), " marker 'c' ", randstring()), # 8
    string(randstring(), " Marker 'a' ", randstring()), # 9
    "postlude", # 10
    "postlude", # 11
    "postlude", # 12
    "postlude", # 13
]

result = Log.segment(text, r"Marker \'(.*?)\'"i)
expected = Dict(
    "a" => Log.Segment(4,9), #,length(text[4:6])),
    "b" => Log.Segment(5,7), #,length(text[5:7])),
    "c" => Log.Segment(6,8), #,length(text[8:9])),
)
assert(sort(collect(keys(result.segments))) == sort(collect(keys(expected))))
assert(all(result.segments[key] == expected[key] for key in keys(expected)))
assert(length(result.beginning) == 3) # "preabmle"
assert(length(result.ending) == 4) # "postlude"

result = Log.segment(text, r"Marker \'(.*?)\'"i, overlapping = false)
expected = Dict(
    "a" => Log.Segment(4,9), #,length(text[4:6])),
)
assert(sort(collect(keys(result.segments))) == sort(collect(keys(expected))))
assert(all(result.segments[key] == expected[key] for key in keys(expected)))
assert(length(result.beginning) == 3) # "preabmle"
assert(length(result.ending) == 4) # "postlude"

# ------------------------------------------------------------------------------

# text = [randstring() for _ in 1:100000]
# @time Log.segment(text, r"(ab)"i)
# @time Log.segment(text, r"(ab)"i, overlapping = false)

# ------------------------------------------------------------------------------

result = Dict(
    "a" => Log.Segment(4,9),
    "b" => Log.Segment(5,7),
    "c" => Log.Segment(6,8),
)
expected = Dict(
    "a" => Log.Segment(4,9),
)
Log.filter_overlapping_ranges!(result)
assert(result == expected)

result = Dict(
    "a" => Log.Segment(4,9),
    "b" => Log.Segment(5,7),
    "c" => Log.Segment(6,8),
)
expected = Dict(
    "b" => Log.Segment(5,7),
    "c" => Log.Segment(6,8),
)
Log.filter_overlapping_ranges!(result, strategy = :keep_lesser)
assert(result == expected)

# ------------------------------------------------------------------------------

# lines = readlines("data/logs/2014-12-02_08-58-09_1048.log")
lines = readlines("data/logs/2018-03-01_15-11-18_51750.log")

# lines = readlines("data/logs/2016-12-14_09-00-53_243818.log")
segmentation = Log.segment(lines, r"workflow \'(.*?)\'"i, overlapping = false)
# segmentation = Log.segment(lines, r"(ef7f844122bc455497615b655d7040b)")

# mat = readcsv("data/kate/1048S_1321V_207N_3K_15E_1234seed_embedded_KATE_clustered.csv")
mat = readcsv("data/kate/51750S_6154V_148N_3K_15E_1234seed_embedded_KATE_clustered_kmeans_51750P_300k.csv")

data = map(f->convert(Int64,f), mat[:,1])
splitted = Log.split_at(data, segmentation)

# filter contiguous duplicates
no_dups = map(seq -> Sequence.filter_contiguous_duplicates(seq), splitted)

# prefixspan = Sequence.convert_to_prefixspan(splitted)
writedlm(
    string("data/kate/",
    length(data),
    "_",
    length(splitted),
    "_sequences_no_duplicates_non_overlapping",
    ".desq"),
    # prefixspan, " ")
    # splitted, "\t")
    no_dups, "\t")
