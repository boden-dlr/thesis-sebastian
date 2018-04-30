using Plots
gr()


# ----------------------------------------------------------------------
# Find correlations
using Stats

x = 20 * randn(1000) + 100
y = x + (10 * randn(1000) + 50)
scatter(x,y)

cov(x,y)
cor(x,y)
corspearman(x,y) # from Stats


# ----------------------------------------------------------------------
# Cross Decomposition

using CrossDecomposition
using Flux, Flux.Data.MNIST
using Base.Iterators: partition

imgs = MNIST.images()

data = [float(hcat(vec.(imgs)...)) for imgs in partition(imgs, 10)]

X = data[1]
Y = data[20]
# scatter(X)
# scatter(Y)

cc = canoncor(X, Y)

coef(cc)
corCC = cor(cc)
scores(cc)

mean(corCC)
median(corCC)
quantile(corCC)
