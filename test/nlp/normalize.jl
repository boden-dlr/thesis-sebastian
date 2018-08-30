using LogClustering.NLP


function normalize(
    document::NLP.Document, vocab::NLP.TermCount;
    padding = 0.0,
    W = 1000)

    max_count = maximum(values(vocab))

    L = length(document)
    N = fill(padding, (L,W))
    for l in 1:L
        for w in 1:W
            if w <= length(document[l])
                word = document[l][w]
                N[l,w] = vocab[word] / max_count
            else
                break
            end
        end
    end
    N
end

raw = readlines("data/datasets/RCE/2014-12-02_08-58-09_1048.log")
doc = map(line->String.(split(line, r"\s+")), raw)
vocab = NLP.count_terms(doc)
N = normalize(doc, vocab)


