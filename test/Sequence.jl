using Base.Test
using LogClustering.Sequence
using LogClustering.Sequence: rows, cols, flatmap
using LogClustering.Sequence: ngram

text = "Some books are to be tasted, others to be swallowed, and some few to be chewed and digested."

N = length(text)

result = ngram(text, 1)
assert(length(result) == N)
assert(result == String[
    "S", "o", "m", "e", " ", "b", "o", "o", "k", "s", " ", "a", "r", 
    "e", " ", "t", "o", " ", "b", "e", " ", "t", "a", "s", "t", "e", 
    "d", ",", " ", "o", "t", "h", "e", "r", "s", " ", "t", "o", " ", 
    "b", "e", " ", "s", "w", "a", "l", "l", "o", "w", "e", "d", ",", 
    " ", "a", "n", "d", " ", "s", "o", "m", "e", " ", "f", "e", "w", 
    " ", "t", "o", " ", "b", "e", " ", "c", "h", "e", "w", "e", "d", 
    " ", "a", "n", "d", " ", "d", "i", "g", "e", "s", "t", "e", "d", 
    "."])

result = ngram(text)
assert(length(result) == N-1)
assert(result == String[
    "So", "om", "me", "e ", " b", "bo", "oo", "ok", "ks", "s ", " a", 
    "ar", "re", "e ", " t", "to", "o ", " b", "be", "e ", " t", "ta", 
    "as", "st", "te", "ed", "d,", ", ", " o", "ot", "th", "he", "er", 
    "rs", "s ", " t", "to", "o ", " b", "be", "e ", " s", "sw", "wa", 
    "al", "ll", "lo", "ow", "we", "ed", "d,", ", ", " a", "an", "nd", 
    "d ", " s", "so", "om", "me", "e ", " f", "fe", "ew", "w ", " t", 
    "to", "o ", " b", "be", "e ", " c", "ch", "he", "ew", "we", "ed", 
    "d ", " a", "an", "nd", "d ", " d", "di", "ig", "ge", "es", "st", 
    "te", "ed", "d."])

result = ngram(text, 3)
assert(length(result) == N-2)
assert(result == String[
    "Som", "ome", "me ", "e b", " bo", "boo", "ook", "oks", "ks ", 
    "s a", " ar", "are", "re ", "e t", " to", "to ", "o b", " be", 
    "be ", "e t", " ta", "tas", "ast", "ste", "ted", "ed,", "d, ", 
    ", o", " ot", "oth", "the", "her", "ers", "rs ", "s t", " to", 
    "to ", "o b", " be", "be ", "e s", " sw", "swa", "wal", "all", 
    "llo", "low", "owe", "wed", "ed,", "d, ", ", a", " an", "and", 
    "nd ", "d s", " so", "som", "ome", "me ", "e f", " fe", "few", 
    "ew ", "w t", " to", "to ", "o b", " be", "be ", "e c", " ch", 
    "che", "hew", "ewe", "wed", "ed ", "d a", " an", "and", "nd ", 
    "d d", " di", "dig", "ige", "ges", "est", "ste", "ted", "ed."])

splitted = split(text)
@show splitted
@show ngram(splitted)

# ----------------------------------------------------------------------



# ----------------------------------------------------------------------

data = collect(rows(rand(1:200, 5, 10)))
prefixspan_format = Sequence.convert_to_prefixspan(data)

# ----------------------------------------------------------------------

# A = rand(1:200, 100)
# using LogClustering.Index
# Index.invert()
