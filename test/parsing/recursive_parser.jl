include(joinpath(pwd(), "src/parsing/recursive_parser.jl"))

# text = [
#     """2014-12-02 08:28:12,985 WARN  - de.rcenvironment.core.communication.connection.impl.ConnectionSetupImpl - Failed to connect to "129.247.111.209:21000"  (Reason: de.rcenvironment.core.communication.common.CommunicationException: Failed to establish JMS connection. Reason: javax.jms.JMSException: Could not connect to broker URL: tcp://129.247.111.209:21000?keepAlive=true. Reason: java.net.ConnectException: Connection refused, Connection details: activemq-tcp:129.247.111.209:21000(autoRetryDelayMultiplier=1.5, autoRetryInitialDelay=5, autoRetryMaximumDelay=300, connectOnStartup=true))123,123""",
#     """2014-12-02 08:28:28,541 DEBUG - de.rcenvironment.core.component - ServiceEvent REGISTERED - {de.rcenvironment.core.component.execution.api.ComponentExecutionController}={rce.component.execution.id=ecb9b2f6-0c02-4fb9-b0fd-dfb339a17a76, service.id=262} - de.rcenvironment.core.component""",
#     ]

text = readlines("data/datasets/RCE/2014-12-02_08-58-09_1048.log")
text = readlines("data/datasets/RCE/2016-12-14_09-00-53_243818.log")

# text = ["_123.465_"]

labels = [
    (Label("rce_datetime"), r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}", parse_rce_datetime),
    (Label("ipv4"), r"\d{3}\.\d{3}\.\d{3}\.\d{3}", identity),
    (Label("german_float"), r"\d+\,\d+", parse_comma_separated_float),
    (Label("float"), r"\d+\.\d+", parse_float),
    (Label("int"), r"\d+", parse_int),
]

parsed = Vector{Any}(length(text))
@time for i in eachindex(text)
    parsed[i] = parse(text[i], labels)
    # parsed = @time sort(parsed, by=t->t[1].start)
    # for i in 1:length(parsed)-1
    #     a = parsed[i]
    #     b = parsed[i+1]
    
    #     assert(a[1].stop +1 == b[1].start)
    # end
end
# parsed
