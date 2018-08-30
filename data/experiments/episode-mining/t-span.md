# Experiment 1

data = readdlm("data/embedding/playground/2018-07-25_51750_assignments_and_reconstruction_error.csv")
max_duration = 10
min_support  = 3
min_utililty = 0.00005308
max_repetition = 2

# with min_sup for events

indmax(secs) = 690
minimum(secs) = 1.74e-7
median(secs) = 4.76e-7
mean(secs) = 0.0049514993858632665
maximum(secs) = 2.229890293
sum(secs) = 4.273143969999999

# without min_sup for events

indmax(secs) = 715
minimum(secs) = 2.54e-7
median(secs) = 5.92e-7
mean(secs) = 0.004929268214368483
maximum(secs) = 2.174973125
sum(secs) = 4.2539584690000005

# Experiment 2 - long run finding big rocks

max_duration = 16
min_support  = 25
min_utililty = 0.00005308   # max_duration:20
max_repetition = 2

# run 1
indmax(secs) = 715
minimum(secs) = 1.74e-7
median(secs) = 4.83e-7
mean(secs) = 0.047666957414831984
maximum(secs) = 40.600019058
sum(secs) = 41.136584249
