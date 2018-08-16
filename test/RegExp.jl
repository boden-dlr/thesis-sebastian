using LogClustering.RegExp
using DataStructures

set = [
    ["Some", "books", "are", "to", "be", "tasted"],
    ["others", "to", "be", "swallowed"],
    ["and", "some", "few", "to", "be", "chewed", "and", "digested"],
    ["to", "be", "or", "not", "to", "be"],
    ["to", "be", "or", "not", "to", "be", "this", "is", "the", "question"],
]
regexp = RegExp.infer(set, regex=true)
for line in set
    line_joined = join(line, "")
    @show match(regexp, line_joined)
end

set = [
    ["to", "be", "or", "not", "to", "be"],
    ["to", "be", "or", "not", "to", "be", "this", "is", "the", "question"],
    ["to", "be", "or", "not", "to", "be,", "this", "is", "the", "question"],
]
regexp = RegExp.infer(set, regex=true)
for line in set
    line_joined = join(line, "")
    @show match(regexp, line_joined)
end

set = [
    String["%RCEDATETIME%", " ", "DEBUG", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication", ".", "transport", ".", "jms", ".", "activemq", ".", "internal", ".", "ActiveMQConnectionFilterPlugin", " ", "-", " ", "Accepting", " ", "TCP"," ", "JMS", " ", "connection", " ", "from", " ", "%IPv4%"],
    String["%RCEDATETIME%", " ", "DEBUG", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication", ".", "transport", ".", "jms", ".", "common", ".", "InitialInboxConsumer", " ", "-", " ", "Remote", "-", "initiated", " ", "connection", " ", "established", ",", " ", "sending", " ", "handshake", " ", "response", " ", "to", " ", "%PATH%"],
]
regexp = RegExp.infer(set, regex=true)

set = [
String["%RCE_DATETIME%", " ", "DEBUG", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication", " ", "-", " ", "ServiceEvent", " ", "REGISTERED", " ", "-", " ", "{", "de", ".", "rcenvironment", ".", "core", ".", "communication", ".", "rpc", ".", "RemoteServiceCallService", "}", "=", "{", "component", ".", "name", "=", "Remote", " ", "Service", " ", "Call", " ", "Service", ", ", "component", ".", "id", "=", "%INT%", ", ", "service", ".", "id", "=", "%INT%", "}", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication"],
String["%RCE_DATETIME%", " ", "DEBUG", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication", " ", "-", " ", "ServiceEvent", " ", "REGISTERED", " ", "-", " ", "{", "de", ".", "rcenvironment", ".", "core", ".", "communication", ".", "rpc", ".", "ServiceProxyFactory", "}", "=", "{", "component", ".", "name", "=", "Service", " ", "Proxy", " ", "Factory", ", ", "component", ".", "id", "=", "%INT%", ", ", "service", ".", "id", "=", "%INT%", "}", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication"],
String["%RCE_DATETIME%", " ", "DEBUG", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication", " ", "-", " ", "ServiceEvent", " ", "REGISTERED", " ", "-", " ", "{", "de", ".", "rcenvironment", ".", "core", ".", "communication", ".", "connection", ".", "api", ".", "ConnectionSetupService", ", ", "de", ".", "rcenvironment", ".", "core", ".", "utils", ".", "incubator", ".", "ListenerProvider", "}", "=", "{", "component", ".", "name", "=", "Connection", " ", "Setup", " ", "Service", ", ", "component", ".", "id", "=", "%INT%", ", ", "service", ".", "id", "=", "%INT%", "}", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication"],
String["%RCE_DATETIME%", " ", "DEBUG", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "configuration", ".", "internal", ".", "OsgiListenerRegistrationServiceImpl", " ", "-", " ", "Registering", " ", "MessageChannelLifecycleListener", " ", "listener", " ", "on", " ", "behalf", " ", "of", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication", ".", "connection", ".", "impl", ".", "ConnectionSetupServiceImpl", "@", "%HEX_ID%"],
String["%RCE_DATETIME%", " ", "DEBUG", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication", " ", "-", " ", "ServiceEvent", " ", "REGISTERED", " ", "-", " ", "{", "de", ".", "rcenvironment", ".", "core", ".", "communication", ".", "channel", ".", "MessageChannelLifecycleListener", "}", "=", "{", "service", ".", "id", "=", "%INT%", "}", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication"],
String["%RCE_DATETIME%", " ", "DEBUG", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication", " ", "-", " ", "ServiceEvent", " ", "REGISTERED", " ", "-", " ", "{", "de", ".", "rcenvironment", ".", "core", ".", "command", ".", "spi", ".", "CommandPlugin", "}", "=", "{", "component", ".", "name", "=", "Plugin", " ", "for", " ", "'cn'", " ", "Commands", ", ", "component", ".", "id", "=", "%INT%", ", ", "service", ".", "id", "=", "%INT%", "}", " ", "-", " ", "de", ".", "rcenvironment", ".", "core", ".", "communication"],
]

reps = collect(keys(Dict("%RCE_DATETIME%" => r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}")))

RegExp.infer(set, replacements=reps)

RegExp.infer(set, replacements=reps, regex=true)

