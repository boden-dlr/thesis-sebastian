module Parsing

    include("types.jl")
    export Label, show, LogAttr, EvenLog

    include("event-log.jl")
    export normalize_log_keys, normalize_log_values

    include("primitives.jl")
    export parse_int, parse_float
    export parse_rce_datetime, parse_syslog_datetime

    export Parser
    export Splitter

    include("two_stage_parser.jl")
    export parse_event_log_two_stage

    include("recursive_parser.jl")
    export parse_event_log_recursive

    @deprecate parse_event_log_two_stage parse_event_log_recursive

    parse_event_log = parse_event_log_recursive

end
