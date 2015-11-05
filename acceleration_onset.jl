using XPP
using PyPlot
using DataFrames
using IDAT

close("all")
S = Spec("specs.yml")
D = readtable(joinpath(S.path, "map_curated.csv"));

D[:i_onset] = zeros(size(D)[1])
D[:t_onset] = zeros(size(D)[1])
D[:analyte_onset] = zeros(size(D)[1])

pygui(false)

function plot_onset(D, i, celltype)
  sp = subplot(111)
  x,y = get_xy(D,i)
  ind, rss, xs, ys = find_onset(D,i)
  sp[:plot](x, y)
  sp[:plot](xs, ys)
  sp[:plot](xs[3 + 2:end-3], rss)
  # plot(x[6:end-6], rs)
  sp[:scatter](x[ind], y[ind], color = "r")
  sp[:set_ylim]([0,1.4])
  savefig("plots/$celltype\_$i.png")
  close()
end

for i in 1:size(D)[1]
  if D[i,:complete] == 1
    if D[i,:analyte] != "H2B-mCherry"
      cell_type = D[i, :celltype]
      x,y = get_xy(D,i)
      ind, rss, xs, ys = find_onset(D,i)
      D[i, :i_onset] = ind
      D[:t_onset] = x[ind]
      D[:analyte_onset] = y[ind]
      plot_onset(D, i, cell_type)
    end
  end
end

writetable(joinpath(S.path, "map_curated_onset.csv"), D)



# D = D[D[:complete] .== 1, :]
# #Get HeLa Cells
# H = D[D[:celltype] .== "HeLa", :]
# #Get cells where Securing eGFP was measured
# H = H[H[:analyte] .== "Securin-eGFP", :];
#
# R = D[D[:celltype] .== "RPE1", :]
