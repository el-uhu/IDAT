export time_derivative, smooth, f, find_onset

function time_derivative(x,y)
  dx = x[2:end] - x[1:end-1]
  dy = y[2:end] - y[1:end-1]
  dydx = dy ./ dx
  return(dydx)
end

function smooth(x,y, width)
  y = [mean(y[i-width:i+width]) for i in width+1:length(y)-width]
  x = x[width+1:length(x)-width]
  return(x,y)
end

f(y) = findfirst(y .>= 0.9)

function find_onset(D,i)
  smoothwidth = 3
  width = 3
  x, y = get_xy(D, i, limlow = f);
  #Smooth the data for the calculation of the rate
  xs, ys =  smooth(x,y,smoothwidth)
  #Calculate the rate
  rs = - time_derivative(xs,ys);
  #Running mean of the rate
  rs = Float64[mean(rs[i-width:i+width]) for i in width+1:length(rs)-width]
  #baseline for rescaling of the rate
  bl = mean(rs) + 1 * std(rs)
  #Rate maximum
  rs_max = maximum(rs)
  #If the maximum lies within the baseline range, set baseline to 0
  bl = bl > rs_max ? 0 : bl
  #Rescale the rate
  rss = (rs -bl) / (rs_max - bl)
  #Find the maximum
  i_max = findlast(rss, 1)
  #Find the value to the right of the maximum at which the rate is 25% of the maximal rate
  d_rs_max = abs(rss - 0.25)
  i_hmr = findlast(d_rs_max, minimum(d_rs_max[i_max:end]))
  #Span a window around the peak with a width of 2 * (i_hmr - i_max) and find the left hand 25% rate value
  window = 2 * (i_hmr - i_max)
  lower_bound = maximum([1, i_max - window])
  i_hml = findfirst(d_rs_max[lower_bound:i_max], 0.25) + lower_bound
  #Correct loss of datapoints due to smoothing to get ind for x,y
  ind =  maximum([1, i_hml + smoothwidth + width + 1])
  return(ind, rss, xs, ys)
end
