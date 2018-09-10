module EpisodeMining

    # util functions: support, utility
    include("utility.jl")
    # ms_span
    export random_utility, local_utility, external_utility, avg_utility;
    # mt_span
    export support, relative_support;
    export utility, relative_utility, total_utility;
    export ewu, iesc;

    # min sup mining
    include("recurring_growth.jl")
    export grow, mine_recurring

    # HUEM
    include("mv_span.jl")
    export mv_span, grow_depth_first!;

    include("mt_span.jl")
    export mt_span, s_concatenation;

    # Rule Mining
    include("rule_mining.jl")

end # module
