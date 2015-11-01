using PyPlot
using DataFrames

export new_curation, update_curation, curate!, curate_dataset, add_imin, add_tstep

function new_curation(path)
  D = readtable(joinpath(path, "map.csv"))
  # Add a column to DataFrame to hold information on whether data contains a complete timecourse
  D[:complete] = zeros(size(D)[1])

  # Add a column to DataFrame to hold information on whether where the data is to be cut off
  D[:imin] = zeros(size(D)[1])

  # Add a column to DataFrame to hold information on whether where the data is to be cut off
  D[:imax] = zeros(size(D)[1])

  # Add a column to DataFrame to hold information on whether where the data is to be cut off
  D[:tstep] = zeros(size(D)[1])

  # Add a column to DataFrame to hold comments
  D[:comment] = ["no comment" for i in 1:size(D)[1]]

  # Add a column to DataFrame indicating whether the data has been curated
  D[:curated] = zeros(size(D)[1])
  writetable(joinpath(path, "map_curated.csv"), D)
  return(D)
end

function update_curation(path)
  old_map_curation = readtable(joinpath(path, "map_curated_old.csv"))
  writetable(joinpath(path, "map_curated_old.csv"), old_map_curation)
  new_map_curation = new_curation(path)
  for i in 1:size(old_map_curation)[1]
    id = old_map_curation[i, :data_table]
    match_in_new = findfirst(new_map_curation[:data_table], id)
    if match_in_new != 0
      new_map_curation[match_in_new, :imin] = old_map_curation[i, :imin]
      new_map_curation[match_in_new, :imax] = old_map_curation[i, :imax]
      new_map_curation[match_in_new, :tstep] = old_map_curation[i, :tstep]
      new_map_curation[match_in_new, :comment] = old_map_curation[i, :comment]
      new_map_curation[match_in_new, :complete] = old_map_curation[i, :complete]
      new_map_curation[match_in_new, :curated] = old_map_curation[i, :curated]
    end
  end
  writetable(joinpath(path, "map_curated.csv"), new_map_curation)
  return(new_map_curation)
end

function curate!(A, i, path)
  D = deepcopy(A)
  fname = joinpath(path, "map_curated.csv")
  plot_set(D, drange = [i])
  show()

  println("-"^40)
  println(i, "\t", D[i, :experiment], "\t", D[i, :celltype], "\t", D[i, :well], "\t", D[i, :treatment], "\t", D[i, :dose_uM])
  println("...")

  println("Is the dataset complete? (0 = No, 1 = Yes)")
  complete = int(split(readline(STDIN), "\n")[1])
  X,Y  = get_xy(D,i)

  for n in 1:length(Y)
    println(n,"\t",X[n], "\t",Y[n])
  end

  println("Cut-off? (press enter to take maximum)")
  answer = split(readline(STDIN), "\n")[1]
  if answer == split("\n", "\n")[1]
    imax = length(Y)
  else
    imax = int(answer)
  end

  println("Comments, please... (just press enter to skip)")
  comment = split(readline(STDIN), "\n")[1]
  if comment == split("\n", "\n")[1]
    comment = "no comment"
  end

  println(comment, "\t", typeof(comment))

  D[i, :imin] = findfirst(X .>= 0)
  D[i, :imax] = int(imax)
  D[t, :step] = d = mean(X[2:end] - X[1:end-1])
  D[i, :comment] = comment
  D[i, :complete] = int(complete)
  D[i, :curated] = 1
  println("")
  close()
  return(D[i,:])
end

function curate_dataset(path; skip_processed = true)
  fname = joinpath(path, "map_curated.csv")
  A = readtable(fname)
  i = findfirst(A[:curated], 0)
  if i == 0
    println("no more datasets to curate!")
  else
    println(i)
    A[i,:] = curate!(A, i, path)
    println(A[i,:])
    writetable(fname, A)
  end
end

function add_imin(path)
  fname = joinpath(path, "map_curated.csv")
  A = readtable(fname)
  A[:imin] = zeros(size(A)[1])
  for i in 1:size(A)[1]
    if A[i,:complete] == 1
      x, y = get_xy(A,i)
      A[i, :imin] = findfirst(x .>= 0)
    end
  end
  writetable(fname, A)
end

function add_tstep(path)
  fname = joinpath(path, "map_curated.csv")
  A = readtable(fname)
  A[:tstep] = zeros(size(A)[1])
  for i in 1:size(A)[1]
    if A[i,:complete] == 1
      x, y = get_xy(A,i)
      d = mean(x[2:end] - x[1:end-1])
      A[i, :tstep] = d
    end
  end
  writetable(fname, A)
end
