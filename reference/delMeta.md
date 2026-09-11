# Remove a metadata from being included in the shiny app

Remove a metadata from being included in the shiny app.

## Usage

``` r
delMeta(scConf, meta.to.del)
```

## Arguments

- scConf:

  CellSight config data.table

- meta.to.del:

  metadata to delete. Users can either use the original metadata column
  names or display names. For more information regarding display name,
  see
  [`?modMetaName`](https://openomics.github.io/CellSight/reference/modMetaName.md).
  Multiple metadata can be specified.

## Value

updated CellSight config data.table

## Author

John F. Ouyang

## Examples

``` r
if (FALSE) { # \dontrun{
scConf = delMeta(scConf, c("orig.ident"))
} # }
```
