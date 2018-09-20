using Plots
gr()
# pyplot()

using CSV
using DataFrames
using Query

df = CSV.read("data/experiments/episode-mining/benchmarks_mv_vs_mt.csv")

"""
    short query for dataframes with Query.jl.
"""
function get_run(alg::String, e::Int, df = df)
    q = @from i in df begin
        @where i.alg == alg && i.e == e
        @select {i.alg,i.n,i.time_s,i.memory,i.allocs,i.gctime}
        @collect DataFrame
    end
    # make MiB
    q[:memory_mib] = q[:memory] / 1024^2
    # q[:allocs_k] = q[:allocs] / 1000
    q
end

label_p = nothing
time_p = nothing
memory_p = nothing
allocs_p = nothing
gctime_p = nothing
for alg in ["mv_span", "mt_span"]
    for e in [4,10,100,1000,10000]
        r = get_run(alg, e)

        colors = Dict(
            4    => :orange,
            10   => :red,
            100  => :purple,
            1000 => :blue,
            10000 => :black)
        color = colors[e]

        # markers = Dict(
        #     4    => :circle,
        #     10   => :rect,
        #     100  => :star5,
        #     1000 => :diamond,
        #     10000 => :black)
        # marker = markers[e]
        markersize = 1
        style = alg == "mv_span" ? :solid : :dash
        line = (style,1)
        xscale = :log10
        yaxis = :log10#, (10^-5,Inf))
        # leg = :topleft
        leg = :none

        xlabel="n events"

        l_alg = alg == "mv_span" ? "MV-Span" : "MT-Span"
        label = "$l_alg ($e event types) "

        function plot_initial(y::Symbol, title::String, ylabel::String, yaxis=yaxis)
            plot(r[:n], r[y],
                title = title,
                xlabel=xlabel, ylabel=ylabel, label=label,
                # yticks=7,
                xscale=xscale, yaxis=yaxis, leg=leg,
                line=line, color=color)
                # marker=marker, markersize=markersize)
        end

        if time_p == nothing
            global time_p = plot_initial(:time_s, "runtime", "time in s")
            global memory_p = plot_initial(:memory_mib, "memory", "memory in MiB\n(1024^2)")
            global allocs_p = plot_initial(:allocs, "allocations", "allocations")
            global gctime_p = plot_initial(:gctime, "garbage collection time", "time in s", (:log, (10^-1,Inf)))
        else
            plot!(time_p, r[:n], r[:time_s],
                label=label,
                line=line, color=color)
                # marker=marker, markersize=markersize)
            plot!(memory_p, r[:n], r[:memory_mib],
                label=label,
                line=line, color=color)
                 # marker=marker, markersize=markersize)
            plot!(allocs_p, r[:n], r[:allocs],
                label=label,
                line=line, color=color)
                # , marker=marker, markersize=markersize)
            plot!(gctime_p, r[:n], r[:gctime],
                label=label,
                line=line, color=color)
        end

        global label_p = plot(deepcopy(time_p),
            title = "",
            xlabel="",ylabel="",
            x = [],
            y = [],
            leg=:topright, grid=false, showaxis=false, showlabel=false)
    end
end

function plot_together(p1, p2, widths=[0.7,0.3])
    plot(p1, p2, layout = grid(1,2,widths=widths, heights=[1.0]))
end
time_final = plot_together(time_p, label_p, [0.5, 0.5])
memory_final = plot_together(memory_p, label_p)
allocs_final = plot_together(allocs_p, label_p)
mem_allocs_final = plot_together(memory_p, allocs_p, [0.5, 0.5])
mem_gctime_final = plot_together(memory_p, gctime_p, [0.5, 0.5])
gctime_final = plot_together(gctime_p, label_p)

all_togther = plot(time_final, mem_allocs_final, layout=grid(2,1))

savefig(time_final,         "data/plots/benchmark_mv_mt_time.pdf")
savefig(memory_final,       "data/plots/benchmark_mv_mt_memory.pdf")
savefig(allocs_final,       "data/plots/benchmark_mv_mt_allocs.pdf")
savefig(gctime_final,       "data/plots/benchmark_mv_mt_gctime.pdf")
savefig(mem_allocs_final,   "data/plots/benchmark_mv_mt_memory_allocs.pdf")
savefig(mem_allocs_final,   "data/plots/benchmark_mv_mt_memory_gctime.pdf")
savefig(all_togther,        "data/plots/benchmark_mv_mt_all.pdf")

display(all_togther)
