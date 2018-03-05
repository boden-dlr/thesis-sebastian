using LogClustering.Log

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

assert(result == expected)

readlines("")