function plot_set(D; sp = Union{}, xlim = [0,250], ylim = [0,1.2], drange = Union{}, alpha = 1)
  if sp == Union{}
    fig = figure()
    sp = subplot(111)
  end
  if drange == Union{}
    drange = 1:size(D)[1]
  end
  for i in drange
    c = D[i, :celltype]
    d = D[i, :dose_uM]
    t = D[i, :treatment]
    x,y = get_xy(D, i, limlow = true, rescale = true)
    plot_cell(x, y, c, d, t, sp = sp, alpha = alpha)
  end
  # sp[:set_xlim](xlim)
  sp[:set_ylim](ylim)
  show()
  return(sp)
end

function get_color(celltype, dose, treatment)
  if treatment == "untreated"
    #RPE lighter
    control_colors = Dict(
      "HeLa" => "k",
      "RPE1" => "k",
    )
    return(control_colors[celltype])
  elseif treatment == "Reversine" || treatment == "RO-3306" || treatment == "Flavopiridol"
    n_steps = 5
    maxima = Dict(
      "Reversine" => 1,
      "RO-3306" => 20,
      "Flavopiridol" => 20,
    )
    ranges = [t => collect(0:(maxima[t]/n_steps):maxima[t]) for t in keys(maxima)]
    colors = Dict(
      "HeLa" => Dict(
        "Reversine" => ["#2E150D","#522B1F","#794231","#A35A44","#CF7459","#FC8F6E"], #red
        "Flavopiridol" => ["#121D26","#283C4B","#425D74","#5D809F","#7BA5CD","#9ACBFD"], #blue
        "RO-3306" => ["#04201E","#15473A","#35714E","#659C5A","#A3C761","#EFEE69"], #yellow-green
      ),
      "RPE1" => Dict(
        "Reversine" => ["#2E150D","#522B1F","#794231","#A35A44","#CF7459","#FC8F6E"], #red
        "Flavopiridol" => ["#121D26","#283C4B","#425D74","#5D809F","#7BA5CD","#9ACBFD"], #blue
        "RO-3306" => ["#04201E","#15473A","#35714E","#659C5A","#A3C761","#EFEE69"], #yellow-green
      ),
    )
    i = findfirst(ranges[treatment] .>= dose)
    return(colors[celltype][treatment][i])
  else
    return("b")
  end
end

function plot_cell(x, y, c, d, t; sp = Union{}, alpha = 1, linewidth = 2)
  if sp == Union{}
    fig = figure()
    sp = subplot(111)
  end
  sp[:plot](x,y, color = get_color(c, d, t), alpha = alpha, linewidth = linewidth)
end

q10(X) = quantile(X, 0.10)
q90(X) = quantile(X, 0.90)

function row_wise_f(D, i, imin, f)
  # r = convert(DataArray, D[i, imin:end])'
  r = DataArray(D[i, imin:end])'
  r = filter(x -> !isna(x), r)
  if length(r) == 0
    return(NA)
  else
    return(f(r))
  end
end

function join_data(D, drange; join_how = :outer)
  x = [i => round(get_xy(D,i)[1],0) for i in drange]
  y = [i => get_xy(D,i)[2] for i in drange]
  d = DataFrame(t = x[1], y = y[1])
  for i in 2:drange[end]
    d2 = DataFrame(t = x[i], y = y[i])
    d = join(d, d2, on = :t, kind = join_how)
  end
  d[:mean] = [row_wise_f(d, i, 2, mean) for i in 1:size(d)[1]]
  d[:median] = [row_wise_f(d, i, 2, median) for i in 1:size(d)[1]]
  d[:ql] = [row_wise_f(d, i, 2, q10) for i in 1:size(d)[1]]
  d[:qu] = [row_wise_f(d, i, 2, q90) for i in 1:size(d)[1]]
  return(d)
end


function boxplot_set(D; sp = Union{}, xlim = [0,250], ylim = [0,1.2], drange = Union{})
  if sp == Union{}
    fig = figure()
    sp = subplot(111)
  end
  if drange == Union{}
    drange = 1:size(D)[1]
  end
  X = DataFrame()
  Y = DataFrame()
  for i in drange
    c = D[i, :celltype]
    d = D[i, :dose_uM]
    t = D[i, :treatment]
    x,y = get_xy(D, i)
    plot_cell(x, y, c, d, t, sp = sp)
  end
  sp[:set_xlim](xlim)
  sp[:set_ylim](ylim)
  show()
  return(sp)
end
