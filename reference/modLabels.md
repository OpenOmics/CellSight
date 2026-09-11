# Modify the legend labels for categorical metadata

Modify the legend labels for categorical metadata.

## Usage

``` r
modLabels(scConf, meta.to.mod, new.labels)
```

## Arguments

- scConf:

  CellSight config data.table

- meta.to.mod:

  metadata for which to modify the legend labels. Users can either use
  the actual metadata column names or display names. Please specify only
  one metadata

- new.labels:

  character vector of new legend labels

## Value

updated CellSight config data.table

## Author

John F. Ouyang

## Examples

``` r
if (FALSE) { # \dontrun{
scConf = modLabels(scConf, meta.to.mod = "library", 
                   new.labels = c("Fib", "Primed", "Naive", "RSeT"))
} # }
```
