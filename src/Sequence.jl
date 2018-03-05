module Sequence

function ngram(s, N::Int=2)
    grams = [s[i:i+N-1] for i = 1:(length(s)-N+1)]
    grams
end

end # module Sequence
