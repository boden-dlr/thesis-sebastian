using CuArrays
using Flux
using Flux: onehot, argmax, chunk, batchseq, throttle, crossentropy
using StatsBase: wsample
using Base.Iterators: partition
using CSV
using BSON: @save, @load

# cd(@__DIR__)

# isfile("input.txt") ||
#   download("http://cs.stanford.edu/people/karpathy/char-rnn/shakespeare_input.txt",
#            "input.txt")

# text = collect(readstring("input.txt"))
# alphabet = [unique(text)..., '¿']
# text = map(ch -> onehot(ch, alphabet), text)
# stop = onehot('¿', alphabet)

data = readdlm("data/embedding/playground/2018-07-28_6073_assignments_and_reconstruction_error.csv")

# sequence = [1,2,3,5,4,8,5,1,2,3,7,5,5,1,2,4]
sequence = map(Int64, data[:,1])
events = unique(sequence)
push!(events, -1)
stop = onehot(-1, events)
one_hot_sequence = map(e -> onehot(e, events), sequence)


N = length(events)
max_seqlen = 50
mini_batch = 20
hidden_state = 100
epochs = 250

Xs = collect(partition(batchseq(chunk(one_hot_sequence[1:end-1], mini_batch), stop), max_seqlen))
Ys = collect(partition(batchseq(chunk(one_hot_sequence[2:end], mini_batch), stop), max_seqlen))

# 
# load
#

# @load "data/models/2018-08-02_model_LSTM_1053-2_LSTM_2-128_Dense_128-1053_softmax.bson" m
# @load "data/models/2018-08-02_weights_LSTM_1053-2_LSTM_2-128_Dense_128-1053_softmax.bson" W
# Flux.loadparams!(m, W)

m = Chain(
    LSTM(N, hidden_state),  # unrolled time window?!
    Dropout(0.25),
    LSTM(hidden_state, 128),
    Dense(128, N),
    softmax)

m = gpu(m)

function loss(xs, ys)
    l = sum(crossentropy.(m.(gpu.(xs)), gpu.(ys)))
    Flux.truncate!(m)
    # Flux.reset!(m)
    return l
end

opt = ADAM(params(m), 0.01)
# opt = Flux.ADADelta(params(m))

tx, ty = (gpu.(Xs[5]), gpu.(Ys[5]))
function callback()
    println(Flux.data(loss(tx, ty)))
end

training_data = zip(Xs, Ys) # gpu?
for e in 1:epochs
    info("Epoch: $e")
    Flux.train!(loss, training_data, opt, cb = throttle(callback, 5))
end

# 
# save model
# 

function shortname!(model)
    name = string(model)
    name = replace(name, r"[\s]+", "")
    name = replace(name, r"[\{\}]|Chain|NNlib|Recur|Base|Float64|Int64|true|false", "")
    name = replace(name, r"LSTMCell", "LSTM")
    name = replace(name, r"\)\,", "_")
    name = replace(name, r"\,", "-")
    name = replace(name, r"\-\.", "_")
    name = replace(name, r"[\(\)\,\.\_]+", "_")
    name = replace(name, r"^\_|\_$", "")
    name 
end

name = shortname!(m)

# reset=true
# to_cpu=true

m = cpu(m)
Flux.reset!(m)

@save string("data/models/", Dates.today(), "_", name, "model.bson") m
W = Tracker.data.(params(m))
@save string("data/models/", Dates.today(), "_", name, "_weights.bson") W


# 
# Sampling
# 
Flux.testmode!(m)
m = cpu(m)

function sample(m, alphabet, len; temp = 1)
    Flux.reset!(m)
    buf = IOBuffer()
    c = rand(alphabet)
    for i = 1:len
        write(buf, c)
        c = wsample(alphabet, m(onehot(c, alphabet)).data)
    end
    # return String(take!(buf))
    return Int64.(take!(buf))
end

sample(m, events, 100) |> println

# 
# predict next...
# 

test_sequence = [5,1,2,3,7]
test_6073_60_70 = [53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
test_6073_88_98 = [78, 79, 80, 81, 82, 83, 82, 84, 85, 86, 87]
test_sequence = test_6073_60_70

Flux.reset!(m)
for e in test_sequence
    pred_dist = m(onehot(e, events)).data
    # println(pred_dist)
    ids = map(t->t[2], sort(map(i->(pred_dist[i],i), eachindex(pred_dist)), by=t->t[1], rev=true))
    println(wsample(events, pred_dist), "\t", events[ids][1:40])
end
