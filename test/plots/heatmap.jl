using CSV
using Base.Iterators
using Plots
using PlotRecipes
gr()
# pyplot()
# plotlyjs()

xs = [string("x",i) for i = 1:10]
ys = [string("y",i) for i = 1:4]
# z = float((1:4) * (1:10)')

CVIs = CSV.read(joinpath(pwd(),"data/experiments/deep-kate/plot_cvi_heatmap_train=0.7_test=0.3_algo=auto_files=1048_1357_2407_5495_6073_6482.csv"))

CVIs_M = convert(Matrix, CVIs)
header = string.(names(CVIs))
# header = [Iterators.flatten((s,s) for s in string.(names(CVIs)))...]

p = heatmap(
    header,
    header,
    CVIs_M,
    size=(800,800),
    aspect_ratio=1.0,
    xrotation=62,
    tickfont = font(10),
    # guidefont = font(8),
    # legendfont = font(8),
    )

savefig(p,joinpath(pwd(),
    "data/plots/cvi_heatmap_train=0.7_test=0.3_algo=auto_files=1048_1357_2407_5495_6073_6482.svg"))
