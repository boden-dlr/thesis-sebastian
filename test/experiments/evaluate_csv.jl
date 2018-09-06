using CSV

filename = "data/experiments/deep-kate/test_all_2018-08-29_2241 (Kopie).csv"

csv = nothing
open(filename, "r") do
    global csv = CSV.open(file)
end

