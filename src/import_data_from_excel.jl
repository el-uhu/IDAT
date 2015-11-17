
#Check if sheet name contains pattern [A-Z][0-9][A-Z][0-9], and hence contains data
function is_data_sheet(sheet_name::AbstractString)
    # if typeof(match(r"[A-Z][0-9][A-Z][0-9]", sheet_name[1:4])) != Void
    #     return(true)
    if typeof(match(r"[A-Z][0-9]", sheet_name[1:2])) != Void
        return(true)
    else
        return(false)
    end
end

#Get a list of all sheets containing data in an excel workbook
function get_data_sheets(sheets::Array{Any,1})
    data_sheets = AbstractString[]
    for s in sheets
        if is_data_sheet(s)
            data_sheets = [data_sheets; [s]]
        end
    end
    return(data_sheets)
end

#Get the number of rows of a particular excel sheet
function get_n_rows(excel_file::ExcelReaders.ExcelFile, sheet_name::AbstractString)
    return(excel_file.workbook[:sheet_by_name](sheet_name)[:nrows])
end

#High-level routine to parse data for sheets in excel file as DataFrame into a Dict
function get_data(fname::AbstractString)
    println("retrieving data from $fname")
    excel_file = openxl(fname)
    sheets = excel_file.workbook[:sheet_names]()
    data_sheets = get_data_sheets(sheets)
    println("\t the following sheets were found $([s * ", " for s in data_sheets])")
    return([s => readxl(DataFrame, excel_file, "$s\!A1:H$(get_n_rows(excel_file, s))") for s in data_sheets])
end

#Search directory for files containing a particular key
searchdir(path,key) = filter(x->contains(x,key), readdir(path))

function save_extracted_data(D::Dict, path::AbstractString)
    path = joinpath(path, "extracted")
    try
        run(`mkdir $path`)
    end
    for experiment in keys(D)
        dir = joinpath(path, experiment)
        try
            run(`mkdir $dir`)
        end
        for cell in keys(D[experiment])
            fname = joinpath(dir, "$cell.csv")
            writetable(fname, D[experiment][cell])
        end
    end
end

function save_map_table(D::Dict, fname, path)
    println("Generating map")
    O = readtable(joinpath(path, "overview/ExperimentsOverview.csv"))
    F = DataFrame()
    for n in names(O)
        F[n] = typeof(O[n][1])[]
    end
    println(names(F))
    F[:cell_id] = AbstractString[]
    F[:data_table] = AbstractString[]
    for experiment in sort([k for k in keys(D)])
        E = O[O[:experiment] .== parse(Int, experiment[1:4]), :]
        if D[experiment] != Dict()
          for cell in sort([k for k in keys(D[experiment])])
            if typeof(match(r"[A-Z][0-9][0-9]", cell)) != Void
                well = cell[1:3]
            elseif typeof(match(r"[A-Z][0-9]", cell)) != Void
                well = cell[1:2]
            else
                println("no matching well found $cell")
            end
            println(experiment, well)
            println(E)
            C = E[E[:well] .== well, :]
            v = [C[item][1] for item in names(O)]
            v = [v, ["$experiment\_$cell"]]
            v = [v, [joinpath(path, "extracted", experiment, "$cell.csv")]]
            push!(F,v)
          end
        end
    end
    writetable(joinpath(path, fname), F)
end

function process(specfile)
  println("Loading settings...")
  S = Spec(specfile)
  println("Searching for excel-files in specified directory $(S.path)")
  excel_files = searchdir(S.path, S.key)
  D = [filename[1:end-5] => get_data(joinpath(S.path, filename)) for filename in excel_files];
  println("Saving extracted data...")
  save_extracted_data(D, S.path)
  println("Generating overview map...")
  save_map_table(D, "map.csv", S.path)
end

f(y) = findfirst(y .>= 0.9)

function get_xy(D,i; limlow = f, limup = true, rescale = false, datatype = :Normalized)
  data = readtable(D[i,:data_table])
  x = data[:Time_aligned_]
  y = dropna(data[datatype])
  if D[i,:curated] == 0
    imin = 1
    imax = minimum([length(dropna(x)), length(dropna(y))])
  else
    imin = round(Int, maximum([1, D[i, :imin]]))
    imax = round(Int, D[i, :imax])
  end
  if limlow == true
    imin = imin
  elseif typeof(limlow) == Int64
    imin = limlow
  elseif typeof(limlow) == Function
    imin = limlow(y)
  else
    imin = 1
  end
  if limup == true
    imax = imax
  elseif typeof(limup) == Int64
    imin = limup
  else
    imax = length(y[imin:end])
  end
  y = y[imin:imax]
  x = x[imin:imax]
  if rescale == true
    bl = mean(y[end-5:end])
    y = (y - bl)/(y[1]-bl)
  end
  return(x,y)
end
