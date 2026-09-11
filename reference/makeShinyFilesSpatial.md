# Generate data files required for shiny app (spatial data)

Generate data files required for shiny app, specifically spatial data A
prefix is specified for each set of files to allow for multiple
single-cell datasets in a single Shiny app.

## Usage

``` r
makeShinyFilesSpatial(
  obj,
  scConf,
  shiny.prefix = "sc1",
  shiny.dir = "shinyApp/"
)
```

## Arguments

- obj:

  input Seurat (v3+) object or input file path for h5ad file

- scConf:

  CellSight config data.table

- shiny.prefix:

  specify file prefix

- shiny.dir:

  specify directory to create the shiny app in

## Value

data files required for shiny app

## Author

John F. Ouyang

## Examples

``` r
if (FALSE) { # \dontrun{
makeShinyFilesSpatial(seu, scConf, shiny.prefix = "sc1", shiny.dir = "shinyApp/")
} # }
```
