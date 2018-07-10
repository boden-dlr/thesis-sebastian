using Flux: relu, leakyrelu, sigmoid
using Plots
using Plots.PlotMeasures
using PlotRecipes
gr()


function bent(x)
    ((sqrt(x^2+1)-1)/2)+x
end

# flipped cos (S. Wiesendahl)
function flipped_cos(x)
    x <= 0 ?
        cos(x)-1 :
        1-cos(x)
end

# inv. flipped cos (S. Wiesendahl)
function inv_flipped_cos(x)
    x <= 0 ?
        ( x >= -1 ?
            -acos(x+1) : 
            # 0.01 * x - pi/2) :
            - pi/2) :
        ( x <= 1 ? 
            acos(-x+1) : 
            pi/2)
end


x = linspace(-pi,pi,10000);

p = plot(x, [
    identity,
    sigmoid,
    tanh,
    atan,
    sin,
    relu,
    leakyrelu,
    bent,
    # flipped_cos,
    # inv_flipped_cos,
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
        # "9. flipped cos",
        # "10. inv flipped cos",
        ],
    ylims = (-pi/2,pi/2),
    legend = :bottomright,
    style = :auto,
    line = 3)

savefig("data/plots/activation_functions.png")
