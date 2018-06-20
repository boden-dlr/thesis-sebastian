using LogClustering.NLP
using LogClustering.KATE
using PyCall
using Plots
gr()
using Clustering
using Distances
using LogClustering.ClusteringUtils
using DataStructures
using LogClustering.Validation

# file = readlines("data/datasets/test/syslog")
# file = readlines("data/datasets/RCE/2017-11-28_08-08-42_129250.log")
# file = readlines("data/datasets/RCE/2018-03-01_15-11-18_51750.log")
# file = readlines("data/datasets/RCE/2018-03-01_15-07-59_7296.log")
# file = readlines("data/datasets/RCE/2014-12-02_08-58-09_1048.log")
# file = readlines("data/datasets/RCE/2018-02-09_10-04-25_1286.log")
# file = readlines("data/datasets/RCE/2017-10-19_10-29-57_1387.log")
file = readlines("data/datasets/RCE/2017-02-24_10-26-01_6073.log")
N = length(file)

# DATETIME = r"[a-zA-Z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"
# RCE_DATETIME = r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}"

DATE = r"^\d{4}-\d{2}-\d{2}$"
TIME = r"^[0-9]{2}:[0-9]{2}:[0-9]{2}$"


ID_HEX = r"^(:?(?=.*[a-fA-F])(?=.*[0-9])([0-9a-fA-F]+)|([0-9a-fA-F]+[\-\_])+[0-9a-fA-F]+)$"
match(ID_HEX, "1234567890")
match(ID_HEX, "ABCDEF")
match(ID_HEX, "c11r-8ca99c5cb50d4055a2a57d7f0cb10db7")

match(ID_HEX, "ADEF2")
match(ID_HEX, "ADEF-2")
match(ID_HEX, "ADEF_2")
match(ID_HEX, "ADEF:2")

ID = r"^(:?(?=.*[a-zA-Z])(?=.*[0-9])(:?([0-9a-zA-Z]+)|([0-9a-zA-Z]+[\-\_\:])+[0-9a-zA-Z]+))$"
match(ID, "CONNECTING")
match(ID, "WAITING_TO_RECONNECT")
match(ID, "rce.component.controller.instance=6eac00c1-1277-44c7-adf4-93f62d0f4928")

match(ID, "WAITING_TO_RECONNECT2")
match(ID, "c11r")
match(ID, "c11r-8ca99c5cb50d4055a2a57d7f0cb10db7")
match(ID, "merger24.png")

VERSION = r"^(:?(\d{1,3})\.(\d{1,3})(\.\d{1,3})?([\_\-\+\.a-zA-Z0-9]+)?)$"
match(VERSION, "255.255.255.255") # fails

match(VERSION, "1.2")
match(VERSION, "1.2.Hello")
match(VERSION, "1.2.3")
match(VERSION, "1.2.3RC")
match(VERSION, "1.2.3+")
match(VERSION, "1.2.3-RC")
match(VERSION, "1.2.3_RC")
match(VERSION, "1.2.3-RC1")
match(VERSION, "1.2.3-RC1.0")


MAC = r"^(?:([0-9A-Fa-f]{2}[:-]){13}|([0-9A-Fa-f]{2}[:-]){5})([0-9A-Fa-f]{2})$"
IPv4 = r"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
IPv6 = r"^((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?$"

FLOAT = r"^\d+[\.\,]\d+$"
INT   = r"^\d+$"
HEX   = r"^0x[0-9A-Fa-f]+$"
MIN   = r"^(\d+)m$"
SEC   = r"^(\d+)s$"
MS   = r"^(\d+)ms$"

PATH = r"^([\/\\]|[^\/\0]+[\/\\]|[^\/\0]+:[\/\\]{2})+([^\/\0]+[\/\\]{0,2})?$"
match(PATH, "NoPath")
match(PATH, "file.ext")
match(PATH, "Hello-world.org")
match(PATH, "214.6.139.in-addr.arpa")
match(PATH, "tcp://129.247.229.173:21011?keepAlive=true")

match(PATH, "PATH/")
match(PATH, "/PATH")
match(PATH, "/file.ext")
match(PATH, "/PATH/")
match(PATH, "file://")
match(PATH, "file://PATH")
match(PATH, "file://PATH/")
match(PATH, "P:\\rce7\\profiles\\ly_hpc03_wfhost_students_7.0.1\\internal\\shutdown.dat")

FILE = r"^[^\/\.\0]+\.[^\0]{2,4}$"
match(FILE, "file.ext")
match(FILE, "file.ext4")

match(FILE, "not.file.ext")
match(FILE, "not_a_file.ext55")

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

    # pipe = replace(pipe, DATETIME, "%DATETIME%")
    # pipe = replace(pipe, RCE_DATETIME, "%DATETIME%")
    
    pipe = String.(NLP.split_and_keep_splitter(pipe, r"\s+|[\,\;\(\)\[\]\]\{\}\<\>\|\'\"\#]+"))

    # pipe = vcat(map(term->String.(NLP.split_and_keep_splitter(term, r"[\w\p{L}\-\_\.\:\\\/\%]+")), pipe)...)
    
    pipe = map(term->replace(term, PATH, "%PATH%"), pipe)
    # pipe = map(term->replace(term, URI, "%URI%"), pipe)

    # pipe = vcat(map(term->String.(NLP.split_and_keep_splitter(term, r"[\w\p{L}\-\_\.\:\%]+")), pipe)...)

    pipe = map(term->replace(term, DATE, "%DATE%"), pipe)
    pipe = map(term->replace(term, TIME, "%TIME%"), pipe)
    pipe = map(term->replace(term, MAC, "%MAC%"), pipe)
    pipe = map(term->replace(term, IPv6, "%IPv6%"), pipe)
    
    pipe = vcat(map(term->String.(NLP.split_and_keep_splitter(term, r"[\:\=]+")), pipe)...)

    pipe = map(term->replace(term, IPv4, "%IPv4%"), pipe)
    pipe = map(term->replace(term, FLOAT, "%FLOAT%"), pipe)
    pipe = map(term->replace(term, FILE, "%FILE%"), pipe)
    pipe = map(term->replace(term, VERSION, "%VERSION%"), pipe)

    pipe = map(term->replace(term, ID_HEX, "%ID_HEX%"), pipe)
    pipe = map(term->replace(term, HEX, "%HEX%"), pipe)

    pipe = map(term->replace(term, ID, "%ID%"), pipe)

    # pipe = vcat(map(term->String.(NLP.split_and_keep_splitter(term, r"[\w\p{L}\-\_\%]+")), pipe)...)
    # pipe = vcat(map(term->String.(NLP.split(term, r"[^\w\p{L}\-\_\%]+", keep=false)), pipe)...)

    # pipe = vcat(map(term->String.(NLP.split_and_keep_splitter(term, r"[\w\p{L}\-\_\.\%]+")), pipe)...)
    # # pipe = vcat(map(term->String.(NLP.split(term, r"[^\w\p{L}\-\_\.\%]+", keep=false)), pipe)...)
    # pipe = map(term->replace(term, IPv4, "%IPv4%"), pipe)
    
    pipe = vcat(map(term->String.(NLP.split_and_keep_splitter(term, r"[\-\_\.]+")), pipe)...)

    pipe = map(term->replace(term, INT, "%INT%"), pipe)
    
    pipe = map(term->replace(term, MIN, "%MINUTES%"), pipe)
    pipe = map(term->replace(term, SEC, "%SECONDS%"), pipe)
    pipe = map(term->replace(term, MS,  "%MILLIS%"),  pipe)
    
    # @show pipe
    push!(piped, pipe)
end

for (line,pipe) in collect(zip(file, piped))[rand(1:N, 100)]
    # if contains(line,"ms")
        @show line
        info(pipe)
        println("---")
    # end
end


terms = NLP.terms(piped)
termcount = NLP.count_terms(piped, terms=terms)

# n = length(termcount)
# max = maximum(values(termcount))
# for (i,key) in enumerate(keys(termcount))
#     cut = 0.01
#     # if i <= cut*n || i >= (1-cut)*n
#     if i <= cut*n
#         termcount[key] = max
#         println("\"", key, "\"\t", termcount[key])
#     end
# end
termcount["DEBUG"]
termcount["INFO"]
termcount["WARN"]
termcount["ERROR"]


# 
# normalize / encode
# 

normalized = hcat(KATE.normalize(piped, termcount)...)'

# lookup = DataStructures.OrderedDict(map(t->t[2]=>t[1] ,enumerate(keys(termcount))))
# MAX = maximum(map(length, file))
# normalized = hcat(map(line->rpad(map(term->lookup[term]^2, line),MAX,0),piped)...)'



@pyimport umap

seed = rand(1:10000)
# seed = 7040

n_neighbors=10
n_components=2

# U = umap.UMAP()
U = umap.UMAP(
    random_state=seed,
    n_neighbors=n_neighbors,
    n_components=n_components)

umapped = U[:fit_transform](normalized)
umapped_t = umapped'





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

radius = 0.3
clustered = dbscan(umapped_t, radius)

assignments = clustering_to_assignments(clustered)
C = assignments_to_clustering(assignments)

# figure = scatter(umapped[:,1], umapped[:,2],
#     marker_z = assignments,
#     labels = ["raw clustered"])

figure_raw = scatter3d(umapped[:,1], umapped[:,2], umapped[:,3],
    marker_z = assignments,
    labels = ["raw clustered"])

#
# find outliers in clusters
#

function split_cluster(cluster)

    lines = Vector{Array{String,1}}()
    for line in cluster
        push!(lines, piped[line])
    end

    splitted = Vector{Array{Int64,1}}()

    if length(lines) <= 1
        return [cluster]
    else
        ls = float(map(length,lines))
        med_line = median(ls)
        # @show var(ls, mean=med_line)
        std_line = std(ls, mean=med_line)
        stays = Vector{Int64}()
        splits = Vector{Int64}()
        for line in cluster
            if length(piped[line]) > med_line + std_line
                push!(splits,line)
            else
                push!(stays,line)
            end
        end
        push!(splitted, stays)
        if length(splits) == 1
            push!(splitted, splits)
        elseif length(splits) >= 1
            append!(splitted, split_cluster(splits))
        end

        # new_clusters = collect(Iterators.filter(
        #     line -> length(piped[line]) > med_line+std_line,
        #     piped[cluster]))
        # @show length(new_clusters)
        return splitted
    end
end



joined = Dict{Int64,Vector{Int64}}()
untouched = Vector{Array{Int64,1}}()
for cluster in C
    splitted = split_cluster(cluster)
    
    for (i,c) in enumerate(splitted)
        if i == 1
            push!(untouched, c)
        else
            for line in c
                n = length(piped[line])
                if haskey(joined, n)
                    inside = NLP.terms(map(l->piped[l],joined[n]))
                    candidate = NLP.terms([piped[line]])
                    common = intersect(inside, candidate)
                    if length(common) > 0.95 * length(inside)
                        push!(joined[n], line)
                    else
                        push!(untouched, [line])
                    end
                else
                    joined[n] = [line]
                end
            end
        end
    end
end
# @show joined

for n in keys(joined)
    for line in joined[n]
        info(join(piped[line]))
    end
    println("----")
end

C_refined = vcat(untouched, collect(values(joined)))
assignments_refined = clustering_to_assignments(C_refined)

figure_refined = scatter3d(umapped[:,1], umapped[:,2], umapped[:,3],
    marker_z = assignments_refined,
    labels = ["refined clustered"])

        # terms = NLP.terms(lines)
        # # @show length(terms), typeof(terms)
        # termcount = NLP.count_terms(lines, terms=terms)
        # # n = length(termcount)
        # # max = maximum(values(termcount))
        # # min = minimum(values(termcount))
        # med = median(collect(values(termcount)))
        # # @show n, min, max, n/min, n/max, min/n, max/n
        # # @show collect(Iterators.filter(iv->iv[2][2] < med, enumerate(collect(termcount))))



# uniques = unique(map(line->line[min(3,end)],piped))
# uniques = unique(map(line->line[min(3,end)],piped))
# uniques = unique(map(line->line[min(4,end)],piped))


C_counts = map(t->t[1] => length(t[2]),enumerate(C))
outlier_treshold = round(Int, N*0.01)
# outlier_treshold = 3
outliers = map(kv->kv[1], filter(kv->kv[2] <= outlier_treshold, collect(C_counts)))

C_sorted = sort(C, by=length, rev=true)
C_refined_sorted = sort(C_refined, by=length, rev=true)

for (i,c) in enumerate(C_sorted[:])
    print_c = false

    for (j,line) in enumerate(c)
        # if piped[line][1] == "at"

        if length(piped[line]) > 3 && piped[line][3] in ["ERROR","WARN"] #,"INFO"]
            print_c = true
            break
        elseif i in outliers
            # print_c = true
            # break
        end
    end

    if print_c
        info(string(i, "\t", length(c)), "\t outlier: ", i in outliers)
        for (j,line) in enumerate(c)
            println(j, "    ", line, "    ", file[line])
            info(join(piped[line]))
            # info(join(normalized[line,:], " "))
        end
        println("---")
    end
end
# uniques



validation = sdbw(umapped_t, C, dense=false)
validation2 = sdbw(umapped_t, C_refined, dense=false)
DC_raw = [view(umapped_t,:,c) for c in C]
DC_refined = [view(umapped_t,:,c) for c in C_refined]
betacv1 = betacv(DC_raw)
betacv2 = betacv(DC_refined)

N
seed
length(C)
length(outliers)
validation

function format_float(f)
    @sprintf "%1.2e" f
end

figures = plot(figure_raw, figure_refined)

savefig(figures, string(
    "data/experiments/",
    now(), "_",
    "n=", N, "_",
    "seed=", seed, "_",
    "dbscan_radius=", radius, "_",
    "clusters=", length(C), "_",
    "outliers=", length(outliers), "_",
    "outlier_treshold=", outlier_treshold, "_",
    "umap_nghbrs=", n_neighbors, "_",
    "umap_dim=", n_components, "_",
    "sdbw_raw=", format_float(validation), "_",
    "sdbw_refined=", format_float(validation2), "_",
    "betacv_raw=", format_float(betacv1), "_",
    "betacv_refined=", format_float(betacv2),
    ".png"))
