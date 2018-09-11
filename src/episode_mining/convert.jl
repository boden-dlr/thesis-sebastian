using DataStructures: OrderedDict

function convert_full_to_ranged(
    full::OrderedDict{Vector{Int64},Vector{Vector{Int64}}})

    return OrderedDict(map(
        kv->kv[1] => map(vs->vs[1]:vs[end], kv[2]),
        collect(full)))
end

# test
# fully = OrderedDict{Vector{Int64},Vector{Vector{Int64}}}()
# fully[[1,2,3]] = [[1,2,3],[3,4,5],[6,7,8]]
# convert_full_to_ranged(fully)
