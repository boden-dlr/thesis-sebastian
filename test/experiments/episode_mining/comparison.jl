using Test
using LogClustering.EpisodeMining: mv_span, mt_span
using BenchmarkTools
using DataStructures: OrderedDict
using LogClustering.Sort
using DataFrames
using DataFrames: DataFrame
using CSV
using Statistics

function event_types(data)
    unique(data)
end

function random_utilities(data)
    usd = Dict(map(e-> e => rand(1:100), event_types(data)))
    usa = zeros(Statistics.maximum(keys(usd)))
    for (k,v) in usd
        usa[k] = v
    end
    usd, usa
end

function ones_utilities(data)
    usd = Dict(map(e-> e => 1, event_types(data)))
    usa = ones(Statistics.maximum(keys(usd)))
    usd, usa
end

function test()
    bs = OrderedDict{Any,BenchmarkTools.Trial}()

    options = OrderedDict(
        :min_sup           => 2,
        :min_utility       => 0.0,
        :max_reps          => 2,
        :max_gap           => 0,
        :max_time_duration => 20)

    for e in [4,10,100]
        for n in [20_000]# 10,100,1_000,10_000]

        sequence = rand(1:e, n)
        utilities_dict, utilities_array = ones_utilities(sequence)

        bs[(:mv_span,e,n)] = @benchmark begin
        # mv_hueSet =
        mv_span(
            $sequence,
            utilities = $utilities_dict,
            min_sup           = $options[:min_sup],
            min_utility       = $options[:min_utility],
            max_repetitions   = $options[:max_reps],
            max_gap           = $options[:max_gap],
            max_time_duration = $options[:max_time_duration])
        end

        bs[(:mt_span,e,n)] = @benchmark begin
        # mt_moSet, mt_hueSet =
        mt_span(
            $sequence,
            $utilities_array,
            $options[:max_time_duration],
            $options[:min_sup],
            $options[:min_utility],
            $options[:max_reps],
            $options[:max_gap])
        end

        # mv_hueSet = sort(mv_hueSet)
        # mt_moSet = sort(mt_moSet)
        # mt_hueSet = sort(mt_hueSet)

        end # for n
    end # for e
    bs, options
end

bs, ops = test()

df = nothing
for (k,t) in bs
    values = OrderedDict(
        :alg => k[1],
        :e => k[2],
        :n => k[3],
        :time_ns => time(Statistics.minimum(t)),
        :time_ms => time(Statistics.minimum(t)) / 1e6,
        :time_s => time(Statistics.minimum(t)) / 1e9,
        :time_median => time(Statistics.median(t)),
        :time_mean => time(Statistics.mean(t)),
        :time_max => time(Statistics.maximum(t)),
        :gctime => gctime(t),
        :memory => memory(t),
        :memory_KiB => ceil(Int,memory(t) / 1024),
        :memory_MiB => ceil(Int,memory(t) / 1024^2),
        :memory_GiB => ceil(Int,memory(t) / 1024^3),
        :allocs => allocs(t),
        :params => params(t))
    for (ok,ov) in ops
        values[ok] = ov
    end
    if df == nothing
        global df = DataFrame(values)
    else
        push!(df, values)
    end
end

CSV.write("data/experiments/episode-mining/benchmarks_mv_vs_mt_20_000.csv", df)
