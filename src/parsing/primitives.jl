#
# Parsing utils
#
using Dates
using DataStructures: OrderedDict
using LogClustering.Parsing: Label


function parse_rce_datetime(value::AbstractString)
    Dates.DateTime(value, dateformat"yyyy-mm-dd HH:MM:SS,sss")
end

function parse_syslog_datetime(value::AbstractString)
    try
        return Dates.DateTime(value, dateformat"u dd HH:MM:SS")
    catch
        return Dates.DateTime(value, dateformat"u  d HH:MM:SS")
    end
end

function parse_float(value::AbstractString, decimal::Char = '.')
    value = replace(value, Regex(string("[^\\d\\",decimal,"]")) => "")
    value = replace(value, decimal => '.')
    parse(Float64, value)
end

function parse_comma_separated_float(value::AbstractString)
    parse_float(value, ',')
end

function parse_int(value::AbstractString)
    parse(Int64,value)
end


Parser = OrderedDict{Symbol,Tuple{Label,Regex,Function}}(
    :rce_datetime    => (Label(:rce_datetime),    r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}", parse_rce_datetime),
    :syslog_datetime => (Label(:syslog_datetime), r"\b[A-Z][a-z]{2}\s{1,2}\d{1,2} \d{2}:\d{2}:\d{2}\b", parse_syslog_datetime),

    :file         => (Label(:file),    r"([\\\/]{0,2}[a-zA-Z0-9]+[\/\\][^\s]+\.[a-zA-Z][^\0]{1,3})\b", identity),
    :path         => (Label(:path),    r"([\\\/]{0,2}[a-zA-Z0-9]+[\/\\][^\s]+)\b", identity),
    :uri          => (Label(:uri),     r"(([\w\d]+[\:\/\\]{1,3})?(?=[^\0]*[\.])([\.\-\/\\]?[\w\d]+[\.\-\/\\])+[\w\d]{2,}?)\b", identity),

    :ipv4         => (Label(:ipv4),    r"\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b", identity),

    :float        => (Label(:float),   r"\b(\d+[\.]\d+(?![\.]))\b", parse_float),
    :float_multi  => (Label(:float),   r"\b(\d+([\,]\d+)?[\.]\d+(?![\.]))\b", parse_float),

    :mac          => (Label(:mac),     r"\b((?:([0-9A-Fa-f]{2}[:-]){13}|([0-9A-Fa-f]{2}[:-]){5})([0-9A-Fa-f]{2}))\b", identity),
    :ipv6         => (Label(:ipv6),    r"\b(((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))))\b", identity),

    :hex_id       => (Label(:hex_id),  r"\b(:?(?=[a-fA-F]*?[0-9])(?=[0-9]*?[a-fA-F])(:?([0-9a-fA-F]+[\-\_\:]?)+[0-9a-fA-F]+))\b", identity),
    :id           => (Label(:id),      r"\b(:?(?=[a-zA-Z]*?[0-9])(?=[0-9]*?[a-zA-Z])(:?([0-9a-zA-Z]+[\-\_\:]?)+[0-9a-zA-Z]+))\b", identity),

    :version      => (Label(:version), r"\b((:?(\d{1,3})\.(\d{1,3})(\.\d{1,3})?([\_\-\+\.a-zA-Z0-9]+)?))\b", identity),
    :int          => (Label(:int),     r"\b\d+\b", parse_int),
    :int_bounds   => (Label(:int),     r"(?:\b|\_)(\d+)(?=\b|\_)", parse_int),
    
    :hex          => (Label(:hex),     r"\b0x[0-9A-Fa-f]+\b", identity),
    )

Splitter = OrderedDict{Symbol,Regex}(
    :positive  => r"\s+|[\.\,\=\:\@\$\(\)\[\]\{\}\\\/\'\"]+", # positive
    :negative  => r"\s+|[^\w\d\-\%\0]+",                      # negative
)
