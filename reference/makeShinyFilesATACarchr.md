# Generate data files required for shiny app (ArchR object)

Generate data files required for shiny app, specifically scATAC-seq data
Six files will be generated, namely (i) the CellSight config
`prefix_conf.rds`, (ii) the single-cell metadata `prefix_meta.rds`,
(iii) the single-cell assays `prefix_assay_X.h5`, (iv) the feature
mapping object config `prefix_gene.rds`, (v) the dimension reduction
embeddings `prefix_dimr.rds` and (vi) the defaults for the Shiny app
`prefix_def.rds` and (vii) the bigwig files for trackplot
`prefix_bw_GRP`. A prefix is specified for each set of files to allow
for multiple single-cell datasets in a single Shiny app.

## Usage

``` r
makeShinyFilesATACarchr(
  obj,
  scConf,
  bigWigGroup = NA,
  assay = NA,
  dimred.to.use = NA,
  shiny.prefix = "sc1",
  shiny.dir = "shinyApp/",
  default.gene1 = NA,
  default.gene2 = NA,
  default.multigene = NA,
  default.dimred = NA,
  ...
)
```

## Arguments

- obj:

  input ArhcR object

- scConf:

  CellSight config data.table

- bigWigGroup:

  categorical group in ArhcR meta.data to group cells by for the
  generation of bigWig files for track plot. Default is NA which does
  not generate any bigWig files.

- assay:

  assay(s) in ArhcR object to use. Multiple assays can now be
  incorporated and all assays are used by default (with the first assay
  being the default assay), which must match one of the following:

  - ArchR objects: "TileMatrix" or "GeneScoreMatrix" or
    "GeneIntegrationMatrix" or "PeakMatrix" or "MotifMatrix", default is
    "PeakMatrix"

- dimred.to.use:

  specify the dimension reduction to use. Default is to use all except
  LSI

- shiny.prefix:

  specify file prefix

- shiny.dir:

  specify directory to create the shiny app in

- default.gene1:

  specify primary default feature (peak or gene or TF) to show, which
  must be present in the default assay

- default.gene2:

  specify secondary default feature (peak or gene or TF) to show, which
  must be present in the default assay

- default.multigene:

  character vector specifying default features to show in bubbleplot /
  heatmap, which be present in the default assay

- default.dimred:

  character vector specifying the two default dimension reductions.
  Default is to use UMAP if not TSNE embeddings

- ...:

  extra arguments to supply to ArchR::getGroupBW

## Value

data files required for shiny app

## Author

John F. Ouyang

## Examples

``` r
if (FALSE) { # \dontrun{
makeShinyFilesATACarchr(ArchR, scConf, 
                        shiny.prefix = "sc1", shiny.dir = "shinyApp/")
} # }
```
