
# file = readlines("data/datasets/test/syslog")
# file = readlines("data/datasets/RCE/2017-11-28_08-08-42_129250.log")
# file = readlines("data/datasets/RCE/2018-03-01_15-11-18_51750.log")
# file = readlines("data/datasets/RCE/2018-03-01_15-07-59_7296.log")
# file = readlines("data/datasets/RCE/2014-12-02_08-58-09_1048.log")
# file = readlines("data/datasets/RCE/2018-02-09_10-04-25_1286.log")
# file = readlines("data/datasets/RCE/2017-10-19_10-29-57_1387.log")
file = readlines("data/datasets/RCE/2017-02-24_10-26-01_6073.log")
# file = readlines("/home/sebastian/data/log/1999_kddcup.data.corrected")[rand(1:4_898_431, 10_000)]
# file = readlines("/home/sebastian/data/log/event-logs/real/BPI Challenge 2017.xes")[rand(1:4_898_431, 10_000)]
N = length(file)

SYSLOG_DATETIME = r"[a-zA-Z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"
RCE_DATETIME = r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}"

DATE = r"^\d{4}-\d{2}-\d{2}$"
TIME = r"^[0-9]{2}:[0-9]{2}:[0-9]{2}$"


ID_HEX = r"^(:?(?=.*[a-fA-F])(?=.*[0-9])([0-9a-fA-F]+)|([0-9a-fA-F]+[\-\_])+[0-9a-fA-F]+)$"
match(ID_HEX, "1234567890")
match(ID_HEX, "ABCDEF")
match(ID_HEX, "c11r-8ca99c5cb50d4055a2a57d7f0cb10db7")

match(ID_HEX, "ADEF2")
match(ID_HEX, "ADEF-2")
match(ID_HEX, "ADEF_2")
match(ID_HEX, "ADEF:2")

ID = r"^(:?(?=.*[a-zA-Z])(?=.*[0-9])(:?([0-9a-zA-Z]+)|([0-9a-zA-Z]+[\-\_\:])+[0-9a-zA-Z]+))$"
match(ID, "CONNECTING")
match(ID, "WAITING_TO_RECONNECT")
match(ID, "rce.component.controller.instance=6eac00c1-1277-44c7-adf4-93f62d0f4928")

match(ID, "WAITING_TO_RECONNECT2")
match(ID, "c11r")
match(ID, "c11r-8ca99c5cb50d4055a2a57d7f0cb10db7")
match(ID, "merger24.png")

VERSION = r"^(:?(\d{1,3})\.(\d{1,3})(\.\d{1,3})?([\_\-\+\.a-zA-Z0-9]+)?)$"
match(VERSION, "255.255.255.255") # fails

match(VERSION, "1.2")
match(VERSION, "1.2.Hello")
match(VERSION, "1.2.3")
match(VERSION, "1.2.3RC")
match(VERSION, "1.2.3+")
match(VERSION, "1.2.3-RC")
match(VERSION, "1.2.3_RC")
match(VERSION, "1.2.3-RC1")
match(VERSION, "1.2.3-RC1.0")


MAC = r"^(?:([0-9A-Fa-f]{2}[:-]){13}|([0-9A-Fa-f]{2}[:-]){5})([0-9A-Fa-f]{2})$"
IPv4 = r"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
IPv6 = r"^((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?$"

FLOAT = r"^\d+[\.\,]\d+$"
INT   = r"^\d+$"
HEX   = r"^0x[0-9A-Fa-f]+$"
MIN   = r"^(\d+)m$"
SEC   = r"^(\d+)s$"
MS   = r"^(\d+)ms$"

PATH = r"^([\/\\]|[^\/\0]+[\/\\]|[^\/\0]+:[\/\\]{2})+([^\/\0]+[\/\\]{0,2})?$"
match(PATH, "NoPath")
match(PATH, "file.ext")
match(PATH, "Hello-world.org")
match(PATH, "214.6.139.in-addr.arpa")
match(PATH, "tcp://129.247.229.173:21011?keepAlive=true")

match(PATH, "PATH/")
match(PATH, "/PATH")
match(PATH, "/file.ext")
match(PATH, "/PATH/")
match(PATH, "file://")
match(PATH, "file://PATH")
match(PATH, "file://PATH/")
match(PATH, "P:\\rce7\\profiles\\ly_hpc03_wfhost_students_7.0.1\\internal\\shutdown.dat")

FILE = r"^[^\/\.\0]+\.[^\0]{2,4}$"
match(FILE, "file.ext")
match(FILE, "file.ext4")

match(FILE, "not.file.ext")
match(FILE, "not_a_file.ext55")

URI = r"^([a-zA-Z0-9]+[\:\/]{1,3})?(?=.*[\.])([a-zA-Z0-9]+[\.\-\_\/])+[a-zA-Z0-9]+[\:\=]?$"
match(URI, "HelloWorld")
match(URI, "Hello-world")
match(URI, "Hello.world")
match(URI, "Hello-world.org")
match(URI, "214.6.139.in-addr.arpa")