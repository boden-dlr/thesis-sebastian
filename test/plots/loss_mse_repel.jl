using Plots
gr()

include(joinpath(pwd(), "src/neural_nets/loss.jl"))

x = linspace(-2pi, 2pi, 1000)
y = sin.(x)
r = repel!(deepcopy(y))
p = plot(x, [y,-r],
    labels = ["sin", "-repel"],
    # style = :auto,
    line = 3)
savefig(p, "data/plots/loss_mse_repel.pdf")
