
# file = readlines("data/datasets/test/syslog")
# file = readlines("/home/sebastian/develop/julia/dev/LogClustering.jl/data/datasets/RCE/2017-11-28_08-08-42_129250.log")
# file = readlines("/home/sebastian/develop/julia/dev/LogClustering.jl/data/datasets/RCE/2018-03-01_15-11-18_51750.log")
# file = readlines("/home/sebastian/develop/julia/dev/LogClustering.jl/data/datasets/RCE/2018-03-01_15-07-59_7296.log")
file = readlines("/home/sebastian/develop/julia/dev/LogClustering.jl/data/datasets/RCE/2014-12-02_08-58-09_1048.log")
# file = readlines("/home/sebastian/develop/julia/dev/LogClustering.jl/data/datasets/RCE/2018-02-09_10-04-25_1286.log")
# file = readlines("/home/sebastian/develop/julia/dev/LogClustering.jl/data/datasets/RCE/2017-10-19_10-29-57_1387.log")
N = length(file)

DATETIME = r"[a-zA-Z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"
RCE_DATETIME = r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}"

TIME = r"^[0-9]{2}:[0-9]{2}:[0-9]{2}$"


ID_HEX = r"^(:?(?=.*[a-fA-F])(?=.*[0-9])([0-9a-fA-F]+)$|^([0-9a-fA-F]+[\-\_\:])+[0-9a-fA-F]+)$"
match(ID_HEX, "1234567890")
match(ID_HEX, "ABCDEF")

match(ID_HEX, "ADEF2")
match(ID_HEX, "ADEF-2")
match(ID_HEX, "ADEF_2")
match(ID_HEX, "ADEF:2")

ID = r"^(:?(?=.*[a-zA-Z])(?=.*[0-9])([0-9a-zA-Z]+)$|^([0-9a-zA-Z]+[\-\_\:])+[0-9a-zA-Z]+)$"
match(ID, "CONNECTING")
match(ID, "WAITING_TO_RECONNECT")

match(ID, "WAITING_TO_RECONNECT2")


MAC = r"^(?:([0-9A-Fa-f]{2}[:-]){13}|([0-9A-Fa-f]{2}[:-]){5})([0-9A-Fa-f]{2})$"
IPv4 = r"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
IPv6 = r"^((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?$"

FLOAT = r"^\d+[\.\,]\d+$"
INT   = r"^\d+$"
HEX   = r"^0x[0-9A-Fa-f]+$"
MIN   = r"^\d+m$"
SEC   = r"^\d+s$"
MS   = r"^\d+ms$"

PATH = r"^([/\\]|[^/\0]+[/\\]|[^/\0]+:[/\\]{2})+([^/\0]+[/\\]{0,2})?$"
match(PATH, "NoPath")
match(PATH, "file.ext")
match(PATH, "Hello-world.org")
match(PATH, "214.6.139.in-addr.arpa")

match(PATH, "PATH/")
match(PATH, "/PATH")
match(PATH, "/file.ext")
match(PATH, "/PATH/")
match(PATH, "file://")
match(PATH, "file://PATH")
match(PATH, "file://PATH/")
match(PATH, "P:\\rce7\\profiles\\ly_hpc03_wfhost_students_7.0.1\\internal\\shutdown.dat")

URI = r"^([a-zA-Z0-9]+[\:\/]{1,3})?(?=.*[\.])([a-zA-Z0-9]+[\.\-\_\/])+[a-zA-Z0-9]+[\:\=]?$"
match(URI, "HelloWorld")
match(URI, "Hello-world")
match(URI, "Hello.world")
match(URI, "Hello-world.org")
match(URI, "214.6.139.in-addr.arpa")


piped = Vector{Array{String,1}}()
for (i,line) in enumerate(file)
    if i % 1000 == 0
        info(i)
    end
    # @show line
    
    pipe = deepcopy(line)

    pipe = replace(pipe, DATETIME, "%DATETIME%")
    pipe = replace(pipe, RCE_DATETIME, "%DATETIME%")
    
    pipe = String.(split(pipe, r"\s+|\.$", keep=false))
    pipe = vcat(map(term->String.(split(term, r"[^\w\p{L}\-\_\.\:\\\/\%]", keep=false)), pipe)...)
    
    pipe = map(term->replace(term, PATH, "%PATH%"), pipe)
    pipe = map(term->replace(term, URI, "%URI%"), pipe)

    pipe = vcat(map(term->String.(split(term, r"[^\w\p{L}\-\_\.\:\%]", keep=false)), pipe)...)

    pipe = map(term->replace(term, TIME, "%TIME%"), pipe)
    pipe = map(term->replace(term, MAC, "%MAC%"), pipe)
    pipe = map(term->replace(term, IPv6, "%IPv6%"), pipe)
    pipe = map(term->replace(term, ID_HEX, "%ID_HEX%"), pipe)
    pipe = map(term->replace(term, ID, "%ID%"), pipe)

    # pipe = map(term->replace(term, IPv4, "%IPv4%"), pipe)
    # pipe = vcat(map(term->String.(split(term, r"[^\w\p{L}\-\_\%]", keep=false)), pipe)...)

    pipe = vcat(map(term->String.(split(term, r"[^\w\p{L}\-\_\.\%]", keep=false)), pipe)...)
    pipe = map(term->replace(term, IPv4, "%IPv4%"), pipe)

    pipe = map(term->replace(term, FLOAT, "%FLOAT%"), pipe)
    pipe = map(term->replace(term, INT, "%INT%"), pipe)
    pipe = map(term->replace(term, HEX, "%HEX%"), pipe)

    # pipe = map(term->replace(term, MIN, "%MINUTES%"), pipe)
    # pipe = map(term->replace(term, SEC, "%SECONDS%"), pipe)
    # pipe = map(term->replace(term, MS, "%MILLIS%"), pipe)
    
    # @show pipe
    push!(piped, pipe)
end

for (line,pipe) in collect(zip(file, piped))[rand(1:N, 100)]
    # if contains(line,"ms")
        # @show line
        @show pipe
        println("---")
    # end
end

using LogClustering.NLP
terms = NLP.terms(piped)
termcount = NLP.count_terms(piped, terms=terms)

using LogClustering.KATE
normalized = hcat(KATE.normalize(piped, termcount)...)'

# using DataStructures
# lookup = DataStructures.OrderedDict(map(t->t[2]=>t[1] ,enumerate(keys(termcount))))
# MAX = maximum(map(length, file))
# normalized = hcat(map(line->rpad(map(term->lookup[term]^2, line),MAX,0),piped)...)'


using PyCall
@pyimport umap

seed = rand(1:10000)
# seed = 7040

U = umap.UMAP(
    random_state=seed,
    n_neighbors=5)
# U = umap.UMAP()
umapped = U[:fit_transform](normalized)
umapped_t = umapped'


using Plots
gr()
using Clustering
using Distances


# D = pairwise(Euclidean(), umapped_t)
# clustered = dbscan(D, 0.25, 1)
# assignments = clustered.assignments
# length(unique(assignments))
# Ass = Dict{Int,Vector{Int}}()
# for (i,c) in enumerate(clustered.assignments)
#     if haskey(Ass, c)
#         push!(Ass[c], i)
#     else
#         Ass[c] = [i]
#     end
# end
# C = collect(values(Ass))

radius = 0.4
clustered = dbscan(umapped_t, radius)
C = Vector{Array{Int,1}}()
assignments = zeros(Int, N)
for (i,c) in enumerate(clustered)
    c = vcat(c.core_indices, c.boundary_indices)
    push!(C,c)
    for n in c
        assignments[n] = i
    end
end


figure = scatter(umapped[:,1], umapped[:,2],
    marker_z = assignments,
    labels = ["clustered"])



uniques = unique(map(line->line[min(2,end)],piped))
# uniques = unique(map(line->line[min(3,end)],piped))
# uniques = unique(map(line->line[min(4,end)],piped))



C_counts = map(t->t[1] => length(t[2]),enumerate(C))
outlier_treshold = round(Int, N*0.01)
outliers = map(kv->kv[1], filter(kv->kv[2] <= outlier_treshold, collect(C_counts)))

for (i,c) in enumerate(C[outliers])
    info(string(i, "\t", length(c)))
    for (j,line) in enumerate(c)
        # if piped[line][1] == "at"
        if piped[line][min(2,end)] in ["ERROR","WARN","INFO"]
            println(j, "    ", line, "    ", file[line])
        end
    end
    println("---")
end


using LogClustering.Validation
validation = sdbw(umapped_t, C)


N
seed
length(C)
validation


savefig(figure, string(
    "data/experiments/",
    now(), "_",
    N, "_",
    seed, "_",
    radius, "_",
    length(C), "_",
    length(outliers), "_",
    outlier_treshold, "_",
    validation,
    ".png"))
