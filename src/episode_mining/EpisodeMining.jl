module EpisodeMining

    # support- and utility-functions
    include("utility.jl")
    export random_utility;

    # for mv_span
    export local_utility, external_utility, avg_utility;

    # for mt_span
    export support, relative_support;
    export utility, relative_utility, total_utility;
    export ewu, iesc;

    # frequent episode mining (FEM)
    include("recurring_growth.jl")
    export grow, mine_recurring

    # high utility episode mining (HUEM)
    include("mv_span.jl")
    export mv_span, grow_depth_first!;

    include("mt_span.jl")
    export mt_span, s_concatenation;

    # episode rule mining (ERM)
    include("rule_mining.jl")

end # module
