using LogClustering.RegExp
using DataStructures

set = [
    ["Some", "books", "are", "to", "be", "tasted"],
    ["others", "to", "be", "swallowed"],
    ["and", "some", "few", "to", "be", "chewed", "and", "digested"],
    ["to", "be", "or", "not", "to", "be"],
    ["to", "be", "or", "not", "to", "be", "this", "is", "the", "question"],
]
regexp = RegExp.infer(set)
for line in set
    line_joined = join(line, "")
    @show match(regexp, line_joined)
end

set = [
    ["to", "be", "or", "not", "to", "be"], # TOOD: fix prefix
    ["to", "be", "or", "not", "to", "be", "this", "is", "the", "question"],
    ["to", "be", "or", "not", "to", "be,", "this", "is", "the", "question"],
]
regexp = RegExp.infer(set)
for line in set
    line_joined = join(line, "")
    @show match(regexp, line_joined)
end

set = [
    String["%RCEDATETIME%", " ", "DEBUG", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication", ".", "transport", ".", "jms", ".", "activemq", ".", "internal", ".", "ActiveMQConnectionFilterPlugin", " ", "-", " ", "Accepting", " ", "TCP"," ", "JMS", " ", "connection", " ", "from", " ", "%IPv4%"],
    String["%RCEDATETIME%", " ", "DEBUG", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication", ".", "transport", ".", "jms", ".", "common", ".", "InitialInboxConsumer", " ", "-", " ", "Remote", "-", "initiated", " ", "connection", " ", "established", ",", " ", "sending", " ", "handshake", " ", "response", " ", "to", " ", "%PATH%"],
]
regexp = RegExp.infer(set)

# ----------------------------------------------------------------------

# log = readlines("data/logs/2014-12-02_08-58-09_1048.log")
# tokenized = readdlm("data/kate/1048S_1143V_207N_3K_15E_1234seed_tokenized.csv", ',', String)
# # clustered = readcsv("data/kate/1048S_1321V_207N_4K_10E_1234seed_embedded_KATE_clustered.csv")
# clustered = readcsv("data/kate/1048S_1321V_207N_3K_15E_1234seed_embedded_KATE_clustered.csv")

log = readlines("data/logs/2018-03-01_15-11-18_51750.log")
tokenized = readdlm("data/kate/51750S_6154V_148N_3K_15E_1234seed_tokenized.csv", ',', String)
# clustered = readcsv("data/kate/51750S_6154V_148N_3K_15E_1234seed_embedded_KATE_clustered_kmeans_51750P_300k.csv")
clustered = readcsv("data/kate/51750S_6154V_148N_3K_15E_1234seed_embedded_KATE_clustered_dbscan_30000P.csv")

grouped = Dict{Int64,Vector{Tuple{Int64,Array{String,1}}}}()

assert(size(tokenized)[1] == length(clustered))
for (i, assignment) in enumerate(clustered)
    cluster = convert(Int64, assignment)
    # joined = join(tokenized[i,:], " ")
    if !haskey(grouped, cluster)
        grouped[cluster] = Vector{Tuple{Int64,Array{String,1}}}()
    end
    push!(grouped[cluster], (i, tokenized[i,:]))
end


for group in collect(keys(grouped))
    members = grouped[group]
    indices = map(m->m[1],members)
    samples = map(m->m[2],members)
    regexp = RegExp.infer(samples,
        insert_placeholder = true,
        replacements = Dict("timestamp" => "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}"))    

    matches = 0
    limit = 7
    counter = 1
    nonmatched = Vector{Tuple{Int64,String}}()
    for (i,line) in enumerate(log)
        if i in indices
            if typeof(match(regexp, line)) != Void
                matches += 1
            elseif counter <= limit
                push!(nonmatched, (i, line))
                counter += 1
            end
        end
    end

    if length(members) != matches
        println()
        println()
        # for (i, member) in members[1:min(7,end)]
        #     println(i, "\t", join(filter(w->length(w)>0,member), " "))
        # end
        # for (i,line) in nonmatched
        #     println(i, " ", line)
        # end
        @show length(members), matches
        println(regexp)
    end
end

println(length(unique(clustered)))
