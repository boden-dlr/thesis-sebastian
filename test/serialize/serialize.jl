using LogClustering.Serialize


# 
# serialize a dictionary
# 
dict = Dict(
    "hello" => pi,
    :world => "\"test\"",
    "int" => 1,
    "float" => 2.3346)

simple = Serialize.convert(String, dict)
println(simple)

# 
# serialize a dictionary to a JSON object
# 
json = Serialize.convert(String, dict, 
    assignment=": ", delim=", ",
    left="{", right="}",
    quotes="\"", escape=":\"{}")

println(json)


# 
# serialize an ordered dictionary
# 
using DataStructures: OrderedDict

odict = OrderedDict(
    "hello" => 1,
    :world => 2.0)

str = Serialize.convert(String, odict)
println(str)
