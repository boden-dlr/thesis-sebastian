# LogClustering

This project consists of different tools and models for:

    * parsing log files
    * dimensionality reduction by autoencoders (KATE, DeepKATE)
    * clustering low dimensional data (DBSCAN)
    * anomaly detection by reconstruction error
    * serial episode mining (MV-Span, MT-Span)
        * serial episode rule mining
    * recurrent neural net models (LSTM, peephole LSTSM, Bi-LSTM)

## Install

The project is written for julia `v0.7` and should be compatible for `v1.0` with
some minor refactoring (package updates and imports).

### make the project locally available

```sh
mkdir ~/.julia/config
touch ~/.julia/config/startup.jl
```

add to `startup.jl`:
```julia
push!(LOAD_PATH, "/path/to/local/julia/reps")
```

### use the package

See the Julia documentations for package usage: [Pkg (v1.0)](https://docs.julialang.org/en/v1/stdlib/Pkg)

Getting started:

*The Pkg REPL-mode is entered from the Julia REPL using the key ].*

```sh
cd /path/to/repository/LogClustering.jl
```

```pkg
(v1.0) pkg> activate .

(LogClustering) pkg > instantiate
```

or make the package available for the standard environment:

```pkg
(v1.0) pkg> add /path/to/repository/LogClustering.jl

(v1.0) pkg> build LogClustering
```

## Structure

Datasets and Results of experiments (import from archived datasets and `data` folder):

    data/

Package source code:

    src/
        clustering/         # clustering utilities
        datastructures/     # special datastructures
        episode_mining/     # episode mining & episode rule mining
        gui/                # qt5 prototype gui
        neural_nets         # datastructures for neural nets with Flux.jl
        parsing/            # Event-Log parser
        regexp/             # Regular-Expression inference
        serialize/          # serialization for dictionaries
        validation/         # CVIs and crossvalidation

Tests, Models, Experiments, Notebooks and Playground:

    test/
        clustering/         # dbscan, k-means, fuzzy-c-means
        correlation/        # pearson vs. spearman correlations
        datasets/           # iscx + DeepKATE
        embeddings/         # python models for embeddings
        episode_mining/     # MV-Span and MT-Span tests
        experiments/        # different experiments
        matrices/           # basic linear algebra in julia
        models/             # Flux.jl models
        nlp/                # nlp tests
        notebooks/          # Jupyter notebooks (tutorials)
        parsing/            # unit tests for parsers
        playground/         # playground for new ideas
        plots/              # plotting scripts
        regex/              # unit tests for RE inference
        serialize/          # unit tests for serialization
        validation/         # unit tests for CVIs and Cross-Validation
