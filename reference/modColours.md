# Modify the colour palette for categorical metadata

Modify the colour palette for categorical metadata.

## Usage

``` r
modColours(scConf, meta.to.mod, new.colours)
```

## Arguments

- scConf:

  CellSight config data.table

- meta.to.mod:

  metadata for which to modify the colour palette. Users can either use
  the actual metadata column names or display names. Please specify only
  one metadata

- new.colours:

  character vector of new colour palette

## Value

updated CellSight config data.table

## Author

John F. Ouyang

## Examples

``` r
if (FALSE) { # \dontrun{
scConf = modColours(scConf, meta.to.mod = "library", 
                    new.colours = c("black", "darkorange", "blue", "red"))
} # }
```
