# Create a CellSight config data.table

Create a CellSight config data.table containing (i) the single-cell
metadata to display on the Shiny app, (ii) ordering of factors /
categories of categorical metadata and (iii) colour palettes associated
with each metadata.

## Usage

``` r
createConfig(obj, meta.to.include = NA, legendCols = 4, maxLevels = 50)
```

## Arguments

- obj:

  input Seurat (v3+) object or input file path for h5ad file

- meta.to.include:

  columns to include from the single-cell metadata. Default is `NA`,
  which is to use all columns. Users can specify the columns to include,
  which must match one of the following:

  - Seurat objects: column names in `seu@meta.data` i.e.
    `colnames(seu@meta.data)`

  - h5ad files: column names in `h5ad.obs` i.e.
    `h5ad.obs.columns.values`

- legendCols:

  maximum number of columns allowed when displaying the legends of
  categorical metadata

- maxLevels:

  maximum number of levels allowed for categorical metadata. Metadata
  with nlevels \> maxLevels will be discarded automatically

## Value

CellSight config data.table

## Author

John F. Ouyang

## Examples

``` r
if (FALSE) { # \dontrun{
scConf = createConfig(obj)
} # }
```
