module ETL

using Dates
using Glob
using Glob: GlobMatch
# using JuliaDB

struct Dataset
    files::String
    directory::String
end


function unique_rand(rng::UnitRange, n::Integer)
    if length(rng) < n
        error("`n` must be smaller or equal to the total amount of unique elements in `rng`.")
    end
    uniques = Set{eltype(rng)}()
    while length(uniques) < n
        push!(uniques, rand(rng))
    end
    collect(uniques)
end


function extract(dataset::Dataset;
    handle=readlines, take::Integer=-1, randomize=false)
    if take == -1
        files = glob(dataset.files, dataset.directory)
    elseif randomize
        files = glob(dataset.files, dataset.directory)
        files = files[unique_rand(1:length(files), take)]
    else
        files = glob(dataset.files, dataset.directory)[1:take]
    end
    first = handle(files[1])
    data = Vector{typeof(first)}()
    push!(data, first)
    for i in 2:length(files)
        push!(data, handle(files[i]))
    end
    data
end


# struct EventSchema
#     attributes::Array{Symbol}
#     types::Array{Type}
# end


# struct RawEvent
    # id::Int
    # timestamp::String
    # label::String
    # lines::Array{Array{String,1},1}
    # offset::Int
    # endof::Int
# end


struct Event
    id::Int
    timestamp::DateTime
    label::Symbol
    content::Array{String,1}
    range::Tuple{Int,Int}
end

mutable struct MutableEvent
    id::Int
    timestamp::DateTime
    label::Symbol
    content::Array{String,1}
    range::Tuple{Int,Int}
end


struct EventLog
    events::Array{Event,1}
    n::Int
end


function col(eventlog::EventLog, name::Symbol)
    if name == :id
        column = Vector{Int}()
    elseif name == :timestamp
        column = Vector{DateTime}()
    elseif name == :label
        column = Vector{Symbol}()
    elseif name == :content
        column = Vector{Array{String,1}}()
    elseif name == :range
        column = Vector{Tuple{Int,Int}}()
    end
    for event in eventlog.events
        if name == :id
            push!(column, event.id)
        elseif name == :timestamp
            push!(column, event.timestamp)
        elseif name == :label
            push!(column, event.label)
        elseif name == :content
            push!(column, event.content)
        elseif name == :range
            push!(column, event.range)
        end
    end
    column
end


function transform(corpus::Array{Array{String,1},1})
    # https://docs.julialang.org/en/stable/stdlib/dates/#Base.Dates.format-Tuple{Base.Dates.TimeType,AbstractString}
    format = "yyyy-mm-dd HH:MM:SS,sss"

    es = Vector{EventLog}()
    for document in corpus
        id = 0
        me::Union{Void,MutableEvent} = nothing
        events = Vector{Event}()
        for (i,line) in enumerate(document)
            try 
                timestamp = DateTime(line[1:23], format)
                # we are good, we have an event
                if me != nothing
                    push!(events, Event(
                        me.id,
                        me.timestamp,
                        me.label,
                        me.content,
                        me.range
                    ))
                end
                id += 1
                label = strip(line[25:29])
                start = i
                content = [line[30:end]]
                me = MutableEvent(id, timestamp, label, content, (i,i))
            catch
                if me != nothing
                    push!(me.content, line)
                    me.range = (me.range[1],me.range[2]+1)
                end
            end            
        end
        if me != nothing
            push!(events, Event(
                me.id,
                me.timestamp,
                me.label,
                me.content,
                me.range
            ))
        end
        push!(es, EventLog(events, length(events)))
    end
    es
end


function load(es::Array{EventLog})
    db = Vector()
    for eventlog in es
        t = table(
            col(eventlog, :id),
            col(eventlog, :timestamp),
            col(eventlog, :label),
            col(eventlog, :content),
            col(eventlog, :range),
            names = [
                :id,
                :timestamp,
                :label,
                :content,
                :range,
            ],
            pkey = :id
        )
        push!(db, t)
    end
    db
end

export Dataset, extract, transform, load

end # module