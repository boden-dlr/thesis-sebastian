# make project locally available
# mkdir ~/.julia/config
# touch ~/.julia/config/startup.jl
# push!(LOAD_PATH, "path/to/local/julia/projects")

# install python packages
@info "install python packages with Conda"
using Conda
@info "add scikit-learn"
Conda.add("scikit-learn")
@info "add gensim"
Conda.add("gensim")
#Conda.add("PyQt5")
#Conda.add("ipykernel")

# add current path to Python
#ENV["PYTHON"] = Conda.PYTHONDIR
#using PyCall
#build PyCall
