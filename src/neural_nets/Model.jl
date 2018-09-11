module Models

struct Model{T}
    id::Symbol
    name::String
    description::String
    parameters::Union{Void,Dict{Symbol,Any}}
    model::T
end

# """

# """
# function preprocess(model::Model, data) end

"""
    Fit a model to given data.
"""
function fit(model::Model, data) end

"""
    Calculate transformation to embedded space - encode.
"""
function transform(model::Model, data) end

# https://youtu.be/SLE0vz85Rqo?t=1h26m5s
"""
    Calculate inverse transformation to original space - decode.
"""
function reconstruct(model::Model, data) end

"""
    Persist a model to disk.

Formats:

        :AUTO   Decides depeding on the underlying model which format is used. Can be any format.

    binary formats:
        :BSON   Bin­ary JSON is a JSON inspired binary format
        :JLD    JLD is a specific "dialect" of HDF5, which preserves type information.

    text formats:
        :JSON   JSON is a common mostly human readable serialization format.
        :XML    XML is a common mostly machine readable serialization format.

"""
function save(model::Model; format::Symbol = :AUTO) end

"""
    Load a model from disk.

Formats:

    :AUTO   Infer format by file extension.

"""
function load(path::String; format::Symbol = :AUTO)::Model end

end # module Model
