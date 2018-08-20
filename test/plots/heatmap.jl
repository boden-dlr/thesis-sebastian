using CSV
using Base.Iterators
using Plots
using PlotRecipes
gr()
# pyplot()
# plotlyjs()

# cats = 16
# xs = [string("x",i) for i = 1:cats]
# ys = [string("y",i) for i = 1:cats]
# z = float((1:cats) * (1:cats)')
# p = heatmap(xs, ys, z)


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
    # tickfont = font(5),
    # guidefont = font(8),
    # legendfont = font(8),
    yticks = length(header),
    xticks = length(header),
    )

savefig(p,joinpath(pwd(),
    "data/plots/cvi_heatmap_01.pdf"))
