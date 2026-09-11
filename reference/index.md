# Package index

## Building an app

The two functions that make up the standard workflow.
[`makeShinyFiles()`](https://openomics.github.io/CellSight/reference/makeShinyFiles.md)
writes the app’s data files, then
[`makeShinyCodes()`](https://openomics.github.io/CellSight/reference/makeShinyCodes.md)
writes the app itself.

- [`makeShinyFiles()`](https://openomics.github.io/CellSight/reference/makeShinyFiles.md)
  : Generate data files required for shiny app
- [`makeShinyCodes()`](https://openomics.github.io/CellSight/reference/makeShinyCodes.md)
  : Generate code files required for shiny app

## Configuring metadata

A CellSight config (`scConf`) is a `data.table` describing which cell
metadata appears in the app, how it is labelled, ordered and coloured.
Create one with
[`createConfig()`](https://openomics.github.io/CellSight/reference/createConfig.md),
then refine it with the `mod*` helpers.

- [`createConfig()`](https://openomics.github.io/CellSight/reference/createConfig.md)
  : Create a CellSight config data.table
- [`checkConfig()`](https://openomics.github.io/CellSight/reference/checkConfig.md)
  : Checks if CellSight config data.table contains any errors
- [`addMeta()`](https://openomics.github.io/CellSight/reference/addMeta.md)
  : Add a metadata to be included in the shiny app
- [`delMeta()`](https://openomics.github.io/CellSight/reference/delMeta.md)
  : Remove a metadata from being included in the shiny app
- [`modMetaName()`](https://openomics.github.io/CellSight/reference/modMetaName.md)
  : Modify the display name of metadata
- [`modLabels()`](https://openomics.github.io/CellSight/reference/modLabels.md)
  : Modify the legend labels for categorical metadata
- [`modColours()`](https://openomics.github.io/CellSight/reference/modColours.md)
  : Modify the colour palette for categorical metadata
- [`modDefault()`](https://openomics.github.io/CellSight/reference/modDefault.md)
  : Set the default metadata to display
- [`reorderMeta()`](https://openomics.github.io/CellSight/reference/reorderMeta.md)
  : Reorder the order in which metadata appear in the shiny app
- [`showOrder()`](https://openomics.github.io/CellSight/reference/showOrder.md)
  : Shows the order in which metadata will be displayed
- [`showLegend()`](https://openomics.github.io/CellSight/reference/showLegend.md)
  : Shows the legends for single-cell metadata

## Modality-specific writers

[`makeShinyFiles()`](https://openomics.github.io/CellSight/reference/makeShinyFiles.md)
dispatches to these based on the object it is given. Call them directly
only when you need to write a single modality, or to pass
modality-specific arguments.

- [`makeShinyFilesGEX()`](https://openomics.github.io/CellSight/reference/makeShinyFilesGEX.md)
  : Generate data files required for shiny app (scRNA type data)
- [`makeShinyFilesSpatial()`](https://openomics.github.io/CellSight/reference/makeShinyFilesSpatial.md)
  : Generate data files required for shiny app (spatial data)
- [`makeShinyFilesATACsignac()`](https://openomics.github.io/CellSight/reference/makeShinyFilesATACsignac.md)
  : Generate data files required for shiny app (ArchR object)
- [`makeShinyFilesATACarchr()`](https://openomics.github.io/CellSight/reference/makeShinyFilesATACarchr.md)
  : Generate data files required for shiny app (ArchR object)
- [`makeShinyFilesDEG()`](https://openomics.github.io/CellSight/reference/makeShinyFilesDEG.md)
  : Generate data files required for shiny app (scRNA type data)

## HDF5 writers

Lower-level functions that stream expression matrices and data frames
into the chunked HDF5 files the generated app reads from.

- [`makeH5fromSeurat()`](https://openomics.github.io/CellSight/reference/makeH5fromSeurat.md)
  : Make h5 object from Seurat assay data
- [`makeH5fromAnndata()`](https://openomics.github.io/CellSight/reference/makeH5fromAnndata.md)
  : Make h5 object from Anndata assay
- [`makeH5fromArchR()`](https://openomics.github.io/CellSight/reference/makeH5fromArchR.md)
  : Make h5 object from ArchR data
- [`write_df_chunked_hdf5r()`](https://openomics.github.io/CellSight/reference/write_df_chunked_hdf5r.md)
  : Write Data Frame to HDF5 File in Chunks using hdf5r

## Template helpers

Used by the code writers to render the bundled jinjar templates. Of
interest mainly to contributors - see
[`vignette("templates", package = "cellsight")`](https://openomics.github.io/CellSight/articles/templates.md).

- [`scJinjaCfg()`](https://openomics.github.io/CellSight/reference/scJinjaCfg.md)
  : jinjar configuration used by all cellsight code writers
- [`scTrim()`](https://openomics.github.io/CellSight/reference/scTrim.md)
  : Dedent a template block
