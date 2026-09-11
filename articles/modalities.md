# Working with each modality

[`makeShinyFiles()`](https://openomics.github.io/CellSight/reference/makeShinyFiles.md)
is a dispatcher. It inspects the object you give it and writes every
modality it can find, calling the modality-specific writers on your
behalf. Which tabs end up in the app is therefore decided by what is
present in your object plus which arguments you supplied — not by
anything you configure directly.

Code here is not evaluated when the site is built; it needs real data.

## What triggers what

For a **`Seurat`** object:

| modality | writer called | condition |
|----|----|----|
| Gene expression | [`makeShinyFilesGEX()`](https://openomics.github.io/CellSight/reference/makeShinyFilesGEX.md) | always |
| Spatial | [`makeShinyFilesSpatial()`](https://openomics.github.io/CellSight/reference/makeShinyFilesSpatial.md) | `length(obj@images) > 0` |
| ATAC coverage | [`makeShinyFilesATACsignac()`](https://openomics.github.io/CellSight/reference/makeShinyFilesATACsignac.md) | a `peaks` assay **and** `bigWigGroup` supplied |
| DEG tables | [`makeShinyFilesDEG()`](https://openomics.github.io/CellSight/reference/makeShinyFilesDEG.md) | `precomputed.deg` points at an existing file **and** `clusters` given |

For an **`ArchRProject`**, everything routes to
[`makeShinyFilesATACarchr()`](https://openomics.github.io/CellSight/reference/makeShinyFilesATACarchr.md).

For a path ending in **`.h5ad`**,
[`makeShinyFilesGEX()`](https://openomics.github.io/CellSight/reference/makeShinyFilesGEX.md)
handles it (see the caveat below).

The practical consequence: ATAC and DEG tabs are opt-in. A Signac object
with a `peaks` assay produces no track plot unless you also pass
`bigWigGroup`, and that silence is easy to mistake for a bug.

## Gene expression and CITE-seq

The default path. `assay` and `assay.slot` choose what gets written:

``` r

scConf <- createConfig(seu)

makeShinyFiles(
  seu, scConf,
  assay        = "RNA",
  assay.slot   = "data",
  shiny.prefix = "sc1",
  shiny.dir    = "shinyApp/"
)
```

`assay.slot` defaults to `"data"` — the log-normalised values, which is
what you want for visualisation. Leave `assay = NA` to use the object’s
default assay.

For CITE-seq, protein and RNA are separate assays, so build them as
separate prefixes and let the app present them as two datasets:

``` r

makeShinyFiles(seu, scConf, assay = "RNA", shiny.prefix = "sc1", shiny.dir = "shinyApp/")
makeShinyFiles(seu, scConf, assay = "ADT", shiny.prefix = "sc2", shiny.dir = "shinyApp/")

makeShinyCodes(
  shiny.title   = "PBMC CITE-seq",
  shiny.prefix  = c("sc1", "sc2"),
  shiny.headers = c("Gene expression", "Surface protein"),
  shiny.dir     = "shinyApp/"
)
```

`chunkSize` (default 500) controls how many genes are written to HDF5 at
a time. Lower it if you are memory-constrained on a large object; it
affects build-time memory, not the app.

## Spatial transcriptomics

Nothing extra to call — if the Seurat object carries images, the spatial
tabs appear:

``` r

length(seu@images)
#> [1] 1

makeShinyFiles(seu, scConf, shiny.prefix = "sc1", shiny.dir = "shinyApp/")
```

Multi-slide objects are handled: when more than one image is present the
app gains a slide selector on the spatial tabs, and both the zoom and
side-by-side views switch to the multi-slide layout.

The labels in that selector are worth getting right, because they are
derived rather than chosen. If your metadata has a column called exactly
`sample`, CellSight labels each slide with the most common `sample`
value among that slide’s cells; otherwise it falls back to the image
names, `names(obj@images)`. So either add a `sample` column or rename
the images before building:

``` r

names(seu@images)
#> [1] "slice1" "slice1.2"

names(seu@images) <- c("Tumour_A", "Tumour_B")
```

[`makeShinyFilesSpatial()`](https://openomics.github.io/CellSight/reference/makeShinyFilesSpatial.md)
can be called directly, but takes only `obj`, `scConf`, `shiny.prefix`
and `shiny.dir` — there are no spatial-specific tuning arguments at
build time. Point size defaults for spatial panels are set per dataset
by
[`makeShinyCodes()`](https://openomics.github.io/CellSight/reference/makeShinyCodes.md)
via `defPtSiz`.

If you are starting from a raw 10x Visium HD output directory rather
than a finished object, the container ships an `ingest_10x.R` helper
that does the QC, normalisation, clustering and UMAP for you — see
[`vignette("docker")`](https://openomics.github.io/CellSight/articles/docker.md).

## scATAC-seq with Signac

Coverage tracks need bigWig files grouped by some cell metadata, which
is what `bigWigGroup` names. Passing it is what switches the track-plot
tab on:

``` r

makeShinyFiles(
  seu, scConf,
  bigWigGroup  = "seurat_clusters",
  shiny.prefix = "sc1",
  shiny.dir    = "shinyApp/"
)
```

Track plots need `bwtool` and `libbeato` available as command-line tools
on the machine that *serves* the app. They are not R packages and are
not installed by
[`install.packages()`](https://rdrr.io/r/utils/install.packages.html):

``` bash
git clone https://github.com/CRG-Barcelona/libbeato.git
cd libbeato && git checkout 0c30432 && ./configure && make && make install

cd .. && git clone https://github.com/CRG-Barcelona/bwtool.git
cd bwtool && ./configure && make && make check && make install
```

This is the one part of a CellSight app with a non-R runtime dependency.
If you plan to deploy ATAC data to a hosted platform, confirm you can
install system binaries there before you build.

## scATAC-seq with ArchR

`ArchRProject` inputs are recognised by class and routed to
[`makeShinyFilesATACarchr()`](https://openomics.github.io/CellSight/reference/makeShinyFilesATACarchr.md),
which accepts the same defaults arguments as the GEX writer plus
`bigWigGroup`:

``` r

scConf <- createConfig(proj)

makeShinyFiles(
  proj, scConf,
  bigWigGroup    = "Clusters",
  dimred.to.use  = "UMAP",
  shiny.prefix   = "sc1",
  shiny.dir      = "shinyApp/"
)
```

ArchR is not on CRAN — see [its install
instructions](https://github.com/GreenleafLab/ArchR). It is a `Suggests`
dependency, so CellSight installs without it and only needs it for this
path.

## Differential expression tables

The DEG tab is driven by a precomputed table, not computed at build
time. Both `precomputed.deg` and `clusters` are required, and the file
must exist —
[`makeShinyFiles()`](https://openomics.github.io/CellSight/reference/makeShinyFiles.md)
errors if the path is wrong rather than silently skipping:

``` r

makeShinyFiles(
  seu, scConf,
  precomputed.deg = "deg_results.csv",
  clusters        = c("0", "1", "2", "3"),
  shiny.prefix    = "sc1",
  shiny.dir       = "shinyApp/"
)
```

Computing the table first, with Seurat, then handing it over:

``` r

deg <- Seurat::FindAllMarkers(seu, only.pos = FALSE)
write.csv(deg, "deg_results.csv", row.names = FALSE)
```

Keeping this step outside CellSight is deliberate: differential
expression depends on choices — test, covariates, filtering — that
belong to your analysis, not to a visualisation tool.

## AnnData / Scanpy input

Pass the `.h5ad` path as a string where you would pass an object, to
both
[`createConfig()`](https://openomics.github.io/CellSight/reference/createConfig.md)
and
[`makeShinyFiles()`](https://openomics.github.io/CellSight/reference/makeShinyFiles.md):

``` r

reticulate::py_install("anndata")

scConf <- createConfig("pbmc.h5ad")
makeShinyFiles("pbmc.h5ad", scConf, shiny.prefix = "sc1", shiny.dir = "shinyApp/")
```

Reading `.h5ad` goes through **reticulate**, so a Python environment
with `anndata` installed must be discoverable. Metadata columns come
from `h5ad.obs`, so `meta.to.include` takes `obs` column names.

Which matrix is read is controlled by `assay`, which defaults to `"X"`:
that value reads `h5ad.X`, and any other is looked up in `h5ad.layers`.

``` r

makeShinyFiles("pbmc.h5ad", scConf, assay = "X", shiny.prefix = "sc1", shiny.dir = "shinyApp/")
makeShinyFiles("pbmc.h5ad", scConf, assay = "counts", shiny.prefix = "sc1", shiny.dir = "shinyApp/")
```

`assay.slot` has no meaning for `.h5ad` input — AnnData has no slot
concept — and is ignored on this path.

## Calling the writers directly

The modality writers are exported, so you can call one on its own when
you want just that modality, or want to pass arguments the dispatcher
does not forward:

``` r

makeShinyFilesGEX(seu, scConf, gex.assay = "RNA", shiny.prefix = "sc1", shiny.dir = "shinyApp/")
makeShinyFilesSpatial(seu, scConf, shiny.prefix = "sc1", shiny.dir = "shinyApp/")
```

If you do, write every modality into the same `shiny.dir` under the same
`shiny.prefix` before calling
[`makeShinyCodes()`](https://openomics.github.io/CellSight/reference/makeShinyCodes.md)
— the code writer detects which tabs to generate from the data files it
finds there.
