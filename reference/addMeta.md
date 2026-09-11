# Add a metadata to be included in the shiny app

Add a metadata to be included in the shiny app.

## Usage

``` r
addMeta(scConf, meta.to.add, obj, maxLevels = 50)
```

## Arguments

- scConf:

  CellSight config data.table

- meta.to.add:

  metadata to add from the single-cell metadata. Must match one of the
  following:

  - Seurat objects: column names in `seu@meta.data` i.e.
    `colnames(seu@meta.data)`

  - h5ad files: column names in `h5ad.obs` i.e.
    `h5ad.obs.columns.values`

- obj:

  input Seurat (v3+) object or input file path for h5ad file

- maxLevels:

  maximum number of levels allowed for categorical metadata. Metadata
  with nlevels \> maxLevels will throw up an error message

## Value

updated CellSight config data.table

## Author

John F. Ouyang

## Examples

``` r
if (FALSE) { # \dontrun{
scConf = addMeta(scConf, c("orig.ident"), seu)
} # }
```
