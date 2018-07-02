using Flux: relu, leakyrelu, sigmoid
using Plots
using Plots.PlotMeasures
using PlotRecipes
gr()

x = linspace(-pi,pi,10000);

p = plot(x, [
    identity,
    sigmoid,
    tanh,
    atan,
    sin,
    relu,
    leakyrelu,
    # bent identity
    x -> ((sqrt(x^2+1)-1)/2)+x,
    # flipped cos (S. Wiesendahl)
    # x -> x <= 0 ? cos(x)-1 : 1-cos(x),
    # x -> x <= 0 ? exp(cos(x)-1)-1 : log(1-cos(x)+1),
    ],
    labels=[
        "1. identity",
        "2. logistic (sigmoid)",
        "3. tanh",
        "4. arctan",
        "5. sin",
        "6. ReLU",
        "7. leaky ReLU",
        "8. Bent identity",
        # "flipped cos",
        # "flipped exp cos",
        ],
    ylims = (-1.5,1.5),
    legend = :bottomright,
    style = :auto,
    line = 3)

savefig("data/plots/activation_functions.png")
