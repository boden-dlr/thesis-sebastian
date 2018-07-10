using PyCall
@pyimport gensim
const w2v = gensim.models[:word2vec]
const Word2Vec = gensim.models[:word2vec][:Word2Vec]
const load_word2vec_format = gensim.models[:KeyedVectors][:load_word2vec_format]
using DataStructures: OrderedDict, SortedDict, Reverse

# 
# load pretrained model
# 
pretrained = "data/pretrained/word2vec/GoogleNews-vectors-negative300.bin"

# CAUTION: this is heavy as it loads the whole model into RAM (3.6GB)
# model = load_word2vec_format(pretrained, binary=true)
# map(println,keys(model))

queen, king, man, woman, car  = map(model[:get_vector], 
    ["queen", "king", "man", "woman", "car"])

cor(queen, king - man + woman)

cor(man, car)
cor(woman, car)


# 
# train own model
#

# min 2 phrases per document

filename = "/home/sebastian/develop/julia/dev/LogClustering.jl/data/datasets/RCE/2014-12-02_08-58-09_1048.log"
document = readlines(filename)
function tokenize(lines::Array{String})
    ls = Vector{Array{String,1}}()
    for line in lines
        push!(ls, String.(split(line,r"[\s\.\-]+")))
    end
    ls
end
sentences = tokenize(document)

s1, s2 = sentences[1:Int(end/2)], sentences[Int(end/2)+1:end]

n_dimensions = 3

model = Word2Vec(
    min_count=3,
    size=n_dimensions,
    workers=4)
model[:build_vocab](s1)

model[:train](
    s1,
    epochs=15,
    total_examples=length(sentences),
    # total_words=sum(map(length,sentences)),
    )

# filename = "data/trained/word_embedding/base_model.bin"
# model[:save](filename)

model[:vocabulary][:scan_vocab](sentences)
vocab_raw = convert(Dict{String,Int}, model[:vocabulary][:raw_vocab])
vocab = model[:wv][:vocab]
indices = OrderedDict(sort(map(key -> key => vocab[key][:index], keys(vocab)), by=x->x[2]))
counts = OrderedDict(sort(map(key -> key => vocab[key][:count], keys(vocab)), by=x->x[2], rev=true))


DEBUG1 = model[:wv][:word_vec]("DEBUG")

model[:build_vocab](s2, update=true)
model[:train](
    s2,
    epochs=15,
    total_examples=length(sentences),
    # total_words=sum(map(length,sentences)),
    )

DEBUG2 = model[:wv][:word_vec]("DEBUG")

DEBUG1 - DEBUG2
