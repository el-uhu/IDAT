# IDAT
Imaging Data Analysis Toolbox

## Specification file
To use the toolbox, provide a yaml-file containing the following fields:
```yaml
path: "/path/to/folder/containing/excelfiles"
key:  ".xlsx"
```

## Importing new data and updating database

```julia

println("Loading settings...")
#Path to yaml-specifications file
specfile = "specs.yml"
#Load specifications
S = Spec(specfile)

println("Searching for excel-files in specified directory $(S.path)")
#Search the directory specified by S.path for files with the extension S.key
excel_files = IDAT.searchdir(S.path, S.key)

#Extract the data from the excel sheets into a dictionary
D = [filename[1:end-5] => IDAT.get_data(joinpath(S.path, filename)) for filename in excel_files];

println("Saving extracted data...")
#Save the extracted data into the folder specified by S.path
#this generates a a folder for each experiment which contains individual csv-files for each cell
IDAT.save_extracted_data(D, S.path)
println("Generating overview map...")
#Generate an overview map (csv) that serves as an index
IDAT.save_map_table(D, "map.csv", S.path)
#Update the new map with data from the old map
D = update_curation(S.path)
```

## Loading curated dataset

```julia
D = readtable(joinpath(Spec("specs.yml").path, "map_curated.csv"))
#Restrict index using logical indexing
D = D[D[:complete] .== 1, :]
```
