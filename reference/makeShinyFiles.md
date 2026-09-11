# Generate data files required for shiny app

Wrapper function to generate data files required for shiny app. A prefix
is specified for each set of files to allow for multiple single-cell
datasets in a single Shiny app.

## Usage

``` r
makeShinyFiles(
  obj,
  scConf,
  bigWigGroup = NA,
  assay = NA,
  assay.slot = "data",
  dimred.to.use = NA,
  shiny.prefix = "sc1",
  shiny.dir = "shinyApp/",
  default.gene1 = NA,
  default.gene2 = NA,
  default.multigene = NA,
  default.dimred = NA,
  chunkSize = 500,
  precomputed.deg = NA,
  clusters = NA,
  ...
)
```

## Arguments

- obj:

  input Seurat (v3+) object or input file path for h5ad file

- scConf:

  CellSight config data.table

- bigWigGroup:

  categorical group in scATAC datasets to group cells by for the
  generation of bigWig files for track plot. Default is NA which does
  not generate any bigWig files.

- assay:

  assay(s) in single-cell data object to use. Multiple assays can now be
  incorporated and all assays are used by default (with the first assay
  being the default assay), which must match one of the following:

  - Seurat objects: "RNA" or "integrated" assay, default is "RNA"

  - h5ad files: "X" or any assay in "layers", default is "X"

- assay.slot:

  slot in single-cell assay to plot. This is only used for Seurat
  objects (v3+). Default is to use the "data" slot

- dimred.to.use:

  specify the dimension reduction to use. Default is to use all except
  PCA

- shiny.prefix:

  specify file prefix

- shiny.dir:

  specify directory to create the shiny app in

- default.gene1:

  specify primary default gene to show, which be present in the default
  assay for Seurat or X layer in scanpy h5ad

- default.gene2:

  specify secondary default gene to show, which be present in the
  default assay for Seurat or X layer in scanpy h5ad

- default.multigene:

  character vector specifying default genes to show in bubbleplot /
  heatmap, which be present in the default assay for Seurat or X layer
  in scanpy h5ad

- default.dimred:

  character vector specifying the two default dimension reductions.
  Default is to use UMAP if not TSNE embeddings

- chunkSize:

  number of genes written to h5file at any one time. Lower this number
  to reduce memory consumption. Should not be less than 10

## Value

data files required for shiny app

## Author

John F. Ouyang

## Examples

``` r
if (FALSE) { # \dontrun{
makeShinyFiles(seu, scConf,
  shiny.prefix = "sc1", shiny.dir = "shinyApp/",
  default.gene1 = "POU5F1", default.gene2 = "APOA1",
  default.multigene = c("POU5F1", "APOA1", "GPRC5A", "TBXT", "ISL1"),
  default.dimred = "umap"
)
} # }
```
