using CSV
using Plots
using Rsvg
gr()
#plotlyjs()

reduced_file = "kate_8780_68545_129_2_30_out_492s.csv"
reduced = CSV.read(reduced_file, header=true)

clustered_file = "kate_8780_68545_129_2_30_out_492s_dbscan.csv"
clustered_base = split(clustered_file, ".")[1]
cluster = CSV.read(clustered_file, header=true)

p = scatter(reduced[:x], reduced[:y], zcolor=cluster[:cluster])
savefig(p, "$reduced_file\_dbscan_colored.png")

