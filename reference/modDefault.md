# Set the default metadata to display

Set the default metadata to display in the shiny app. Default1 is used
when plotting metadata with gene expression or when plotting two
metadata simultaneously. Default2 is used when plotting two metadata
simultaneously.

## Usage

``` r
modDefault(scConf, default1, default2)
```

## Arguments

- scConf:

  CellSight config data.table

- default1:

  metadata to set as the 1st default metadata to display. Users can
  either use the actual metadata column names or display names

- default2:

  metadata to set as the 2nd default metadata to display. Users can
  either use the actual metadata column names or display names

## Value

updated CellSight config data.table

## Author

John F. Ouyang

## Examples

``` r
if (FALSE) { # \dontrun{
scConf = modDefault(scConf, default1 = "library", default2 = "cluster")
} # }
```
