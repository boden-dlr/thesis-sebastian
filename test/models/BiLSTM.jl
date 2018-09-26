
include(joinpath(pwd(),"src","neural_nets","layers","Parallel.jl"))

# using CuArrays
using Flux
using Flux: onehot, argmax, chunk, batchseq, throttle, crossentropy
using StatsBase: wsample
using Base.Iterators: partition
using BSON: @save, @load
using DataStructures: OrderedDict
using LogClustering.Validation: k_fold_out_of_time

data = readdlm("data/embedding/playground/2018-07-28_6073_assignments_and_reconstruction_error.csv")

# sequence = [1,2,3,5,4,8,5,1,2,3,7,5,5,1,2,4]
sequence = map(Int64, data[:,1])
events = unique(sequence) # alphabet
push!(events, -1)
stop = onehot(-1, events) # alphabet encoded stop-word
one_hot_sequence = map(e -> onehot(e, events), sequence)


N = length(events)
max_seqlen = 40
mini_batch = 10
hidden_state = 200
epochs = 100

Xs = collect(partition(batchseq(chunk(one_hot_sequence[1:end-1], mini_batch), stop), max_seqlen))
Ys = collect(partition(batchseq(chunk(one_hot_sequence[2:end], mini_batch), stop), max_seqlen))
zipped = collect(zip(Xs, Ys))
size(Xs), typeof(Xs), size(Xs[1]), typeof(Xs[1]), size(Xs[1][1]), typeof(Xs[1][1])

# for cv in k_fold_out_of_time(zipped)
# info("folds: ", cv.k, "\t", "round: ", cv.i)
# if cv.i != 3
#     continue
# end

# m = Chain(
#     BiLSTM(N, hidden_state),
#     Dropout(0.33),
#     BiLSTM(hidden_state, hidden_state),
#     Dense(hidden_state, N),
#     softmax)

m = Chain(
    LSTM(N, hidden_state), # BiPLSTM
    Dropout(0.33),
    LSTM(hidden_state, hidden_state), # BiPLSTM
    Dense(hidden_state, N),
    softmax)

m = gpu(m)

function loss(xs, ys)
    l = sum(crossentropy.(m.(gpu.(xs)), gpu.(ys)))
    truncate!(m)
    # Flux.truncate!(m)
    # Flux.reset!(m)
    return l
end

opt = ADAM(params(m), 0.01)
# opt = Flux.ADADelta(params(m))

tx, ty = (gpu.(Xs[5]), gpu.(Ys[5]))
function callback()
    l = Flux.data(loss(tx, ty))
    info("Loss: $l")
end

Flux.testmode!(m, false)
for e in 1:epochs
    info("Epoch: $e")
    # Flux.train!(loss, cv.train, opt, cb = throttle(callback, 5))
    Flux.train!(loss, zipped, opt, cb = throttle(callback, 5))
end

# reset!(m)
# Flux.testmode!(m)
accuracy = Vector{Bool}(0)
for (xs,ys) in zipped
    reset!(m)
    Flux.testmode!(m)
    for i in eachindex(xs)
        preds = m(xs[i]).data
        for n in 1:mini_batch
            y_hat = preds[:,n]
            y = ys[i][:,n]
            # @show indmax(y_hat), indmax(y)
            push!(accuracy, indmax(y_hat) == indmax(y))
        end
    end
end
acc = count(accuracy) / length(accuracy)
info("accuracy: ", acc, " size: ", length(accuracy))
println()


function shortname(model, settings = Dict(), timestamp=true, max=160)
    name = string(model)
    name = replace(name, r"[\s]+", "")
    name = replace(name, r"Parallel{.*?\}\(", "Pa")
    name = replace(name, r"Recur{.*?\}\[", "[")
    name = replace(name, r"[\{\}]|Flux\.|Chain|NNlib|Recur|Base\.|Float64|Int64|Array{Float64\,\d}|TrackedArray\{…\,", "")
    name = replace(name, r"LSTMCell", "LSTM")
    name = replace(name, r"\[\(+?", "[")
    name = replace(name, r"\)+?\]", "]")
    name = replace(name, r"Dropout", "Dout")
    name = replace(name, r"Dense", "D")
    name = replace(name, r"true", "t")
    name = replace(name, r"false", "f")
    name = replace(name, r"sigmoid", "σ")
    name = replace(name, r"Function", "Fn")
    name = replace(name, r"identity", "id")
    name = replace(name, r"reverse", "rev")
    name = replace(name, r"concat", "cat")
    name = replace(name, r"\)\,", "_")
    name = replace(name, r"\,", "-")
    name = replace(name, r"\-\.", "_")
    name = replace(name, r"[\(\)\,\.\_]+", "_")
    name = replace(name, r"\-{2,}", "-")
    name = replace(name, r"\_{2,}", "-")
    name = replace(name, r"^\_|\_$", "")
    name = name[1:min(end,max)]
    if timestamp == true
        datetime = now()
        name = string(Dates.Date(datetime), "_", Dates.Time(datetime), "_", name)
        name = replace(name, r"\.\d{3}", "")
        name = replace(name, r"\:", "-")
    end
    for (k,v) in settings
        if v isa Real
            v = sprint(showcompact, v)
        end
        name = string(name, "_", k, "=", v)
    end
    name
end

name = shortname(m, OrderedDict(
    "a" => N,
    "e" => epochs,
    "l" => max_seqlen,
    "mb" => mini_batch,
    "h" => hidden_state,
    # "cvi" => cv.i,
    # "cvk" => cv.k,
    "acc" => acc,
    "n" => length(accuracy),
    ))

m = cpu(m)
reset!(m)

@save string("data/models/", name, "_model.bson") m
W = Tracker.data.(params(m))
@save string("data/models/", name, "_weights.bson") W

# end


#
# Sample
#

# @load "data/models/2018-08-05_02-02-03_Pa[LSTM_1053-100_LSTM_1053-100]-Fn[id-rev]-cat_Dout_0_66-f_Pa[LSTM_200-100_LSTM_200-100]-Fn[id-rev]-cat_D_200-1053_softmax_e=100_l=40_nb=10_cvi=3_cvk=5_acc=0.025_model.bson" m
# @load "data/models/2018-08-05_02-02-03_Pa[LSTM_1053-100_LSTM_1053-100]-Fn[id-rev]-cat_Dout_0_66-f_Pa[LSTM_200-100_LSTM_200-100]-Fn[id-rev]-cat_D_200-1053_softmax_e=100_l=40_nb=10_cvi=3_cvk=5_acc=0.025_weights.bson" W
# Flux.loadparams!(m, W)

Flux.testmode!(m)
m = cpu(m)

function sample(m, alphabet, len; temp = 1)
    reset!(m)
    buf = IOBuffer()
    c = rand(alphabet)
    for i = 1:len
        write(buf, c)
        c = wsample(alphabet, m(onehot(c, alphabet)).data) #[:,end]
    end
    # return String(take!(buf))
    return Int64.(take!(buf))
end

sample(m, events, 100) |> println


#
# predict
#

test_sequence = [5,1,2,3,7]
test_6073_60_70 = [53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
test_6073_88_98 = [78, 79, 80, 81, 82, 83, 82, 84, 85, 86, 87]
test_sequence = test_6073_60_70

reset!(m)
for e in test_sequence
    pred_dist = m(onehot(e, events)).data[:,end]
    ids = map(t->t[2], sort(map(i->(pred_dist[i],i), eachindex(pred_dist)), by=t->t[1], rev=true))
    println(wsample(events, pred_dist), "\t", events[ids][1:35])
end
