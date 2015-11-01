module IDAT

using YAML
using ExcelReaders
using DataFrames
using PyPlot
export DataFrames

export Spec, plot_set, get_xy

type Spec
  path::AbstractString
  key::AbstractString
end
function Spec(fname::AbstractString)
  D = YAML.load(open(fname))
  return(Spec(D["path"], D["key"]))
end

include("import_data_from_excel.jl")
include("curate_data.jl")
include("plot.jl")

end
