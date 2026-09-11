# Reorder the order in which metadata appear in the shiny app

Reorder the order in which metadata appear in the dropdown menu in the
shiny app.

## Usage

``` r
reorderMeta(scConf, new.meta.order)
```

## Arguments

- scConf:

  CellSight config data.table

- new.meta.order:

  character vector containing new order. All metadata names must be
  included, which can be found at `scConf$ID`

## Value

updated CellSight config data.table

## Author

John F. Ouyang

## Examples

``` r
if (FALSE) { # \dontrun{
scConf = reorderMeta(scConf, scConf$ID[c(1,3,2,4:length(scConf$ID))])
} # }
```
