
mutable struct Label
    label::String
    multi::Char

    Label(label::Union{String,Symbol} = "*",
          multi::Char = '%', 
          single::Char = '*',
          style::Function=uppercase) = begin

        label = string(label)

        if length(label) == 1 && label != string(single)
            throw(ParseError("a single-char label should be '$single'"))
        end
        if occursin(string(multi), label)
            throw(ParseError("a multi-char label should not contain the special char '$multi'"))
        end

        if length(label) == 1
            new(string(label), multi)
        else
            new(style(string(multi, label, multi)), multi)
        end
    end
end

function Base.show(io::IO, l::Label)
    print(io, l.label)
end


struct LogAttr{T,S<:AbstractString,L<:Union{Label,Nothing}}
    value::T
    source::S
    label::L
    occurrence::UnitRange{Int}
end

function LogAttr(value, source)
    LogAttr(value, source, nothing, 0:0)
end


mutable struct EventLog
    log_keys::Vector{Vector{String}}
    log_values::Vector{Vector{LogAttr}}
    log_times::Vector{Int64}
    embeddings::Union{Vector{Vector{Float64}},Nothing}
end
