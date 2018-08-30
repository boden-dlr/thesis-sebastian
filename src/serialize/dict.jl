using Printf

"""
    convert a dictionary to a string.
"""
function Base.convert(t::Type{String}, dict::AbstractDict;
    assignment="=", delim="_", left="", right = "", quotes="", escape = "")

    ops = Vector{String}()
    for (k,v) in dict
        if k isa Union{AbstractString,Symbol}
            k = escape_string(string(k), escape)
            k = string(quotes, k, quotes)
        end
        if v isa Union{AbstractString,Symbol}
            v = escape_string(string(v), escape)
            v = string(quotes, v, quotes)
        end
        if v isa Real && !(v isa Integer)
            v = Printf.@sprintf("%.3f", v)
        end
        push!(ops, string(k, assignment, v))
    end

    string(left, join(ops, delim), right)
end
