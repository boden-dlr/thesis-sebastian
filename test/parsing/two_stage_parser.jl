using LogClustering.Parsing
using LogClustering.Parsing: Label
using Glob

#
# test - event-log parser
#

# file = readlines("data/datasets/test/syslog")
# file = readlines("data/datasets/RCE/2017-11-28_08-08-42_129250.log")
# file = readlines("data/datasets/RCE/2018-03-01_15-11-18_51750.log")
# file = readlines("data/datasets/RCE/2018-03-01_15-07-59_7296.log")
# file = readlines("data/datasets/RCE/2014-12-02_08-58-09_1048.log")
# file = readlines("data/datasets/RCE/2018-02-09_10-04-25_1286.log")
# file = readlines("data/datasets/RCE/2017-10-19_10-29-57_1387.log")
# file = readlines("data/datasets/RCE/2017-02-24_10-26-01_6073.log")
# file = readlines("/home/sebastian/data/log/1999_kddcup.data.corrected")[rand(1:4_898_431, 10_000)]
# file = readlines("/home/sebastian/data/log/event-logs/real/BPI Challenge 2017.xes")[rand(1:4_898_431, 10_000)]

log_files = glob("data/datasets/RCE/*.log") #[1:1]
# log = readlines(log_files[rand(1:length(log_files))])
file = log_files[1]

# for (i,file) in enumerate(log_files)
    info("parse file [$i/",length(log_files),"]: ", file)
    log = readlines(file)

    lp = Tuple{Label,Regex,Function}[
        Parsing.Parser[:rce_datetime],
        Parsing.Parser[:ipv4],
        Parsing.Parser[:float],
        ]

    wp = Tuple{Label,Regex,Function}[
        Parsing.Parser[:hex_id],
        Parsing.Parser[:id],
        Parsing.Parser[:int],
        ]

    event_log = @time Parsing.parse_event_log_two_stage(log,
        line_parser = lp,
        word_parser = wp)

    assert(event_log != nothing)

    # for line in event_log[:log_keys]
    #     @show line
    # end
# end

# 
# test - regular expressions 
#

HEX_ID = Parsing.Parser[:hex_id][2]
# negatives
assert(match(HEX_ID, "1234567890") == nothing)
assert(match(HEX_ID, "ABCDEF") == nothing)
assert(match(HEX_ID, "c11r-8ca99c5cb50d4055a2a57d7f0cb10db7") == nothing)

# positives
assert(match(HEX_ID, "ADEF2") isa RegexMatch)
assert(match(HEX_ID, "ADEF-2") isa RegexMatch)
assert(match(HEX_ID, "ADEF_2") isa RegexMatch)
match(HEX_ID, "ADEF:2") isa RegexMatch # fails

ID = Parsing.Parser[:id][2]
# negatives
assert(match(ID, "CONNECTING") == nothing)
assert(match(ID, "WAITING_TO_RECONNECT") == nothing)
assert(match(ID, "rce.component.controller.instance=6eac00c1-1277-44c7-adf4-93f62d0f4928") == nothing)
assert(match(ID, "merger24.png") == nothing)

# positives
assert(match(ID, "WAITING_TO_RECONNECT2") isa RegexMatch)
assert(match(ID, "c11r") isa RegexMatch)
assert(match(ID, "c11r-8ca99c5cb50d4055a2a57d7f0cb10db7") isa RegexMatch)


VERSION = Parsing.Parser[:version][2]
# negatives
match(VERSION, "255.255.255.255") == nothing # fails

# positives
assert(match(VERSION, "7.1.0.0201604211838_SNAPSHOT") isa RegexMatch)
assert(match(VERSION, "1.2") isa RegexMatch)
assert(match(VERSION, "1.2.Hello") isa RegexMatch)
assert(match(VERSION, "1.2.3") isa RegexMatch)
assert(match(VERSION, "1.2.3RC") isa RegexMatch)
assert(match(VERSION, "1.2.3+") isa RegexMatch)
assert(match(VERSION, "1.2.3-RC") isa RegexMatch)
assert(match(VERSION, "1.2.3_RC") isa RegexMatch)
assert(match(VERSION, "1.2.3-RC1") isa RegexMatch)
assert(match(VERSION, "1.2.3-RC1.0") isa RegexMatch)


PATH = Parsing.Parser[:path][2]
# negatives
assert(match(PATH, "NoPath") == nothing)
assert(match(PATH, "file.ext") == nothing)
assert(match(PATH, "Hello-world.org") == nothing)
assert(match(PATH, "214.6.139.in-addr.arpa") == nothing)
match(PATH, "tcp://129.247.229.173:21011?keepAlive=true") == nothing # fails

# positives
assert(match(PATH, "PATH/") isa RegexMatch)
assert(match(PATH, "/PATH") isa RegexMatch)
assert(match(PATH, "/file.ext") isa RegexMatch)
assert(match(PATH, "/PATH/") isa RegexMatch)
assert(match(PATH, "file://") isa RegexMatch)
assert(match(PATH, "file://PATH") isa RegexMatch)
assert(match(PATH, "file://PATH/") isa RegexMatch)
assert(match(PATH, "P:\\rce7\\profiles\\ly_hpc03_wfhost_students_7.0.1\\internal\\shutdown.dat") isa RegexMatch)

FILE = Parsing.Parser[:file][2]
# negatives
assert(match(FILE, "not.file.ext") == nothing)
assert(match(FILE, "not_a_file.ext55") == nothing)

# positives
assert(match(FILE, "file.ext") isa RegexMatch)
assert(match(FILE, "file.ext4") isa RegexMatch)

URI = Parsing.Parser[:uri][2]
# negatives
assert(match(URI, "HelloWorld") == nothing)
assert(match(URI, "Hello-world") == nothing)

# positives
assert(match(URI, "Hello.world") isa RegexMatch)
assert(match(URI, "Hello-world.org") isa RegexMatch)
assert(match(URI, "214.6.139.in-addr.arpa") isa RegexMatch)


# TODO: test expressions on some examples...

MAC = Parsing.Parser[:mac][2]
IPv4 = Parsing.Parser[:ipv4][2]
IPv6 = Parsing.Parser[:ipv6][2]
# positives
assert(match(IPv6, "0:0:0:0:0:0:0:0") isa RegexMatch)
assert(match(IPv6, "fe80::1ff:fe23:4567:890a") isa RegexMatch)
assert(match(IPv6, "2001:0db8:85a3:0000:0000:8a2e:0370:7334") isa RegexMatch)
assert(match(IPv6, "2001:db8:85a3:0:0:8a2e:370:7334") isa RegexMatch)
assert(match(IPv6, "2001:db8:85a3::8a2e:370:7334") isa RegexMatch)
assert(match(IPv6, "2001:0db8:85a3:0000:0000:8a2e:0370:7334") isa RegexMatch)
# negatives
assert(!(match(IPv6, "::ffff:c000:0280") isa RegexMatch))
assert(!(match(IPv6, "::ffff:192.0.2.128") isa RegexMatch))

FLOAT = Parsing.Parser[:float][2]
INT   = Parsing.Parser[:int][2]
HEX   = Parsing.Parser[:hex][2]

SYSLOG_DATETIME = Parsing.Parser[:syslog_datetime][2]
RCE_DATETIME = Parsing.Parser[:rce_datetime][2]

DATE = r"^\d{4}-\d{2}-\d{2}$"
TIME = r"^[0-9]{2}:[0-9]{2}:[0-9]{2}$"

