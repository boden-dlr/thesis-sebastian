

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
        if contains(label, string(multi))
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
