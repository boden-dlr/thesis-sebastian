using LogClustering.Log

# test with some dummy data
text = [
    string(randstring(), " Prefix 'a' ", randstring()),
    string(randstring(), " Prefix 'b' ", randstring()),
    string(randstring(), " Prefix 'a' ", randstring()),
    string(randstring(), " Prefix 'b' ", randstring()),
    string(randstring(), " Prefix 'c' ", randstring()),
    string(randstring(), " Prefix 'c' ", randstring()),
]

result = Log.split_overlapping(text, r"Prefix \'(.*?)\'")
expected = Dict(
    "a" => text[1:3],
    "b" => text[2:4],
    "c" => text[5:6],
)
assert(result.splitted == expected)
assert(result.prefix == [])
assert(result.suffix == [])

# test with a log file
text = readlines("data/logs/2016-06-01_13-56-53_1273.log")
result = Log.split_overlapping(text, r"Workflow \'(.*?)\'")
for key in keys(result.splitted)
    assert(length(result.splitted[key]) in [94, 40, 37, 55])
end
assert(length(result.prefix) == 729)
assert(length(result.suffix) == 19)
