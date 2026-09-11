# Checks if CellSight config data.table contains any errors

Checks if CellSight config data.table contains any errors. It is useful
and reccomended to run this function if users have motified the
CellSight config manually. Errors can include (i) levels in scConf does
not match that in the Seurat/SingleCellExperiment object, (ii) number of
levels does not match number of colours and (iii) specified colours are
invalid colours.

## Usage

``` r
checkConfig(scConf, obj)
```

## Arguments

- scConf:

  CellSight config data.table

- obj:

  input single-cell object for Seurat (v3+) / SingleCellExperiment data
  or input file path for h5ad / loom files

## Value

any potential error messages

## Author

John F. Ouyang

## Examples

``` r
if (FALSE) { # \dontrun{
checkConfig(scConf, seu)
} # }
```
