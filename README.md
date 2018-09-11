# LogClustering

# Install

# make the project locally available

```sh
mkdir ~/.julia/config
touch ~/.julia/config/startup.jl
```
add to ~/.julia/config/startup.jl
push!(LOAD_PATH, "/path/to/local/julia/reps")

```pkg
(v1.0) pkg> add /path/to/repository/LogClustering.jl
```
```pkg
(v1.0) pkg> build LogClustering
```
