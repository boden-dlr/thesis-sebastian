using Flux
using Flux: Recur, _truncate, prefor, glorot_uniform, initn, gate

function average(mapped)
    D = mapped[1]
    for m in 2:length(mapped)
        D = D .+ mapped[m]
    end
    D = D ./ length(mapped)
    D
end

function concat(values)
    vcat(values...)
end

mutable struct Parallel{L<:Recur}
    layers::Vector{L}
    map::Vector{Function}
    reduce::Function
end

Parallel(layers::Vector{Recur}) = Parallel(layers, fill(identity, length(layers)), concat)

function Parallel(layers::Vector{L};
    map::Dict{Int64,Function} = Dict{Int64,Function}(),
    reduce::Function = concat) where L<:Recur

    mappings::Vector{Function} = fill(identity, length(layers))
    for (k,v) in map
        mappings[k] = v
    end

    return Parallel(layers, mappings, reduce)
end

function (p::Parallel)(xs)
    layers, map, reduce = p.layers, p.map, p.reduce 

    # is ok for nprocs() == 1
    # Base.pmap
    mapped = Base.map(l-> layers[l](map[l](xs)), eachindex(layers))
    
    # mapped = Vector{Any}(length(layers))
    # Threads.@threads for l in eachindex(layers)
    #     mapped[l] = layers[l](map[l](xs))
    # end

    reduce(mapped)
end

Flux.@treelike Parallel

function _prefor_truncate(x)
    if x isa Recur
        x.state = _truncate(x.state)
    elseif x isa Parallel
        for recur in x.layers
            _prefor_truncate(recur)
        end
    end
end

function truncate!(m)
    prefor(_prefor_truncate, m)
end

function _prefor_reset(x)
    if x isa Recur
        x.state = x.init
    elseif x isa Parallel
        for recur in x.layers
            _prefor_reset(recur)
        end
    end
end

function reset!(m)
    prefor(_prefor_reset, m)
end

function Base.reverse(M::Flux.OneHotMatrix{Array{Flux.OneHotVector,1}})
    Flux.OneHotMatrix(M.height, reverse(M.data))
end

function Base.reverse(v::Flux.OneHotVector)
    v
end

function Base.reverse(ta::TrackedArray)
    if length(size(ta.data)) == 2
        flipdim(ta.data,2)
    else
        ta
    end
end

function Base.reverse(b::Bool)
    b
end

# see:
#  "SPEECH RECOGNITION WITH DEEP RECURRENT NEURAL NETWORKS" https://arxiv.org/pdf/1303.5778.pdf
#  "Bidirectional LSTM-CRF Models for Sequence Tagging" https://arxiv.org/pdf/1508.01991.pdf

function Bi(recur::Recur, reduce::Function = concat)
    map = Dict{Int64,Function}(2 => reverse)
    Parallel([recur, deepcopy(recur)], map=map, reduce=reduce)
end

function BiLSTM(in::Int, out::Int, reduce::Function = concat)
    if reduce == average
        Bi(LSTM(in,out), reduce)
    elseif reduce == concat
        if out % 2 == 0
            Bi(LSTM(in,convert(Int64,out/2)), reduce)
        else
            throw(DimensionMismatch("`out` must be a multiple of two for `concat` as reduce function."))
        end
    end
end

# layers = vcat(LSTM(10,5),LSTM(10,5))
# xs = rand(10)
# p1 = Parallel(layers)
# p2 = Parallel(layers, map = Dict{Int64,Function}(2 => reverse))
# p3 = Parallel(layers, map = Dict{Int64,Function}(2 => reverse), reduce = average)

# r1 = p1(xs)
# r2 = p2(xs)
# r3 = p3(xs)

# loss = x -> sum(x)

# l1 = loss(r1)
# l2 = loss(r2)
# l3 = loss(r3)

# Flux.back!(l1)
# Flux.back!(l2)
# Flux.back!(l3)

# l1.tracker.grad
# l2.tracker.grad
# l3.tracker.grad

mutable struct PeepholeLSTMCell{A,V}
    Wx::A
    Wh::A
    Wc::A
    b::V
    h::V
    c::V
end


# For "peephole" LSTM see:
# 2000 Felix A. Gers and Jürgen Schmidhuber. „Recurrent nets that time and count“. In Neural Networks, 2000. IJCNN 2000, Proceedings of the IEEE-INNS-ENNS International Joint  Conference  on,  volume  3,  pages  189–194.  IEEE, 2000.  ISBN 0769506194
# 2005 A. Graves, S. Fernández, and J. Schmidhuber, „Bidirectional LSTM Networks for Improved Phoneme Classification and Recognition“, in Artificial Neural Networks: Formal Models and Their Applications – ICANN 2005, 2005, S. 799–804.
# 2013 A. Graves, „Generating Sequences With Recurrent Neural Networks“, arXiv:1308.0850 [cs], Aug. 2013.
# 2015 J. Wieting, M. Bansal, K. Gimpel, and K. Livescu, „Towards Universal Paraphrastic Sentence Embeddings“, arXiv:1511.08198 [cs], Nov. 2015.
function PeepholeLSTMCell(in::Integer, out::Integer; init = glorot_uniform)
    cell = PeepholeLSTMCell(
        param(init(out*4, in)),  # Wx
        param(init(out*4, out)), # Wh
        param(init(out*4, out)), # Wc
        param(zeros(out*4)),     # b
        param(initn(out)),       # h
        param(initn(out)))       # c
    cell.b.data[gate(out, 2)] = 1
    return cell
end

function (m::PeepholeLSTMCell)(h_, x)
    h, c = h_ # TODO: nicer syntax on 0.7
    o = size(h, 1)
    g = m.Wx*x .+ m.Wh*h .+ m.b
    g_if = m.Wc*c
    input = σ.(gate(g, o, 1) .+ gate(g_if, o, 1))
    forget = σ.(gate(g, o, 2) .+ gate(g_if, o, 2))
    cell = forget .* c .+ input .* tanh.(gate(g, o, 3))
    g_c = m.Wc*cell
    output = σ.(gate(g, o, 4) .+ gate(g_c, o, 4))
    hidden = output .* tanh.(cell)
    return (hidden, cell), hidden
end

Flux.hidden(m::PeepholeLSTMCell) = (m.h, m.c)

Flux.@treelike PeepholeLSTMCell

Base.show(io::IO, l::PeepholeLSTMCell) =
    print(io, "PeepholeLSTMCell(", size(l.Wx, 2), ", ", size(l.Wx, 1)÷4, ")")

PLSTM(a...; ka...) = Recur(PeepholeLSTMCell(a...; ka...))

function BiPLSTM(in::Int, out::Int; reduce::Function = concat)
    if reduce == average
        Bi(PLSTM(in,out), reduce)
    elseif reduce == concat
        if out % 2 == 0
            Bi(PLSTM(in,convert(Int64,out/2)), reduce)
        else
            throw(DimensionMismatch("`out` must be a multiple of two for `concat` as reduce function."))
        end
    end
end
