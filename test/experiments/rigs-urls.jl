using LogClustering.NLP
using LogClustering.KATE

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# 1. encode data by frequency
data = readdlm("/home/sebastian/develop/topic/clustering/LogClustering.jl/data/datasets/RIGS/ulrs.csv", '\t', String)

urls = data[:,1][2:end]

tokenized, wordcount = NLP.tokenize(
    urls,
    splitby = r"[\/\-]",
)

frequency_encoded = KATE.normalize(tokenized, wordcount)

writedlm("/home/sebastian/develop/topic/clustering/LogClustering.jl/data/datasets/RIGS/ulrs_frequency_encoded.csv", frequency_encoded, '\t')

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# 2. plot UMAP reduced clusters with labels and annotations
using Plots
plotlyjs()

umap = readdlm("/home/sebastian/develop/topic/clustering/LogClustering.jl/data/datasets/RIGS/ulrs_frequency_encoded_out_umap_6s.csv", ',', Float64)

labels = data[:,2][2:end]
labels_mapped = map(l-> if l == "indexed" 1 else 0 end, labels)

annotations = map(i-> text("$i", 5, :left), 1:length(labels))

scatter(umap[:,1], umap[:,2],
    zcolor = labels_mapped,
    # seriescolor = :auto,
    # series_annotations = annotations,
    )
