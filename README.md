# LogClustering

# Install

# make the project locally available

```sh
mkdir ~/.julia/config
touch ~/.julia/config/startup.jl
```

add to `startup.jl`:
```julia
push!(LOAD_PATH, "/path/to/local/julia/reps")
```

# use the package

```pkg
(v1.0) pkg> add /path/to/repository/LogClustering.jl

(v1.0) pkg> build LogClustering
```

or do

```sh
cd /path/to/repository/LogClustering.jl
```

```pkg
(v1.0) pkg> activate .

(LogClustering) pkg > instantiate
```
