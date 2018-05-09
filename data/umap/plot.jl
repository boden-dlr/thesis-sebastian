using CSV
using Plots
using Rsvg
gr()
#plotlyjs()

filename = "/home/sebastian/develop/py/hello-umap/kate_8780_68545_129_2_30.csv"
base = split(filename, ".")[1]

data = CSV.read(filename, header=false)

p = scatter(data[1],data[2],color=randomColor)
# p = scatter3d(data[1],data[2],data[3])
savefig(p, "$base\_colored.png")

# current()
