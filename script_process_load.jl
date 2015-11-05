using IDAT
using PyPlot
using DataFrames

close("all")
println("Loading settings...")
specfile = "specs.yml"
S = Spec(specfile)
println("Searching for excel-files in specified directory $(S.path)")
excel_files = IDAT.searchdir(S.path, S.key)
D = [filename[1:end-5] => IDAT.get_data(joinpath(S.path, filename)) for filename in excel_files];
println("Saving extracted data...")
IDAT.save_extracted_data(D, S.path)
println("Generating overview map...")
IDAT.save_map_table(D, "map.csv", S.path)

D = update_curation(Spec("specs.yml").path)
