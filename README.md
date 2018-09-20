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

See the Julia documentations for package usage:

[Pkg (v1.0)](https://docs.julialang.org/en/v1/stdlib/Pkg)

Getting started:

*The Pkg REPL-mode is entered from the Julia REPL using the key ].*

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
