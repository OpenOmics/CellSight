# Deploying a CellSight app

A built CellSight app is a plain Shiny app: a directory containing
`ui.R`, `server.R`, `shinyFunc.R` and its data files. Anything that
hosts Shiny can host it. What is specific to CellSight is which packages
the *serving* machine needs — a much shorter list than the one needed to
build the app.

## What the app directory contains

After
[`makeShinyFiles()`](https://openomics.github.io/CellSight/reference/makeShinyFiles.md)
and
[`makeShinyCodes()`](https://openomics.github.io/CellSight/reference/makeShinyCodes.md),
`shinyApp/` holds, per dataset prefix:

| file                       | contents                                     |
|----------------------------|----------------------------------------------|
| `<prefix>conf.rds`         | the config (`scConf`)                        |
| `<prefix>meta.rds`         | cell metadata                                |
| `<prefix>dimr.rds`         | dimensionality-reduction embeddings          |
| `<prefix>gene.rds`         | feature-name to HDF5-row mapping             |
| `<prefix>def.rds`          | the app’s default gene / metadata selections |
| `<prefix>assay_<assay>.h5` | chunked expression matrix, one per assay     |
| `<prefix>image.rds`        | spatial images and slide names, if spatial   |
| `<prefix>bw.rds`           | bigWig grouping and genome, if ATAC          |
| `<prefix>deg.h5`           | precomputed DEG tables, if supplied          |

plus one shared `ui.R`, `server.R` and `shinyFunc.R`. The whole
directory is self-contained — it does not reference your original Seurat
object — so moving the app is just moving the folder. That is the point
of the HDF5 layout: the app reads only the genes the user asks for
instead of loading the matrix into memory.

## Runtime dependencies

Building needs the packages in `Depends`. *Serving* needs a different
set, declared in `DESCRIPTION` as `Config/Needs/viz`. Install exactly
that on the host:

``` r

install.packages("pak")
pak::pkg_install("CellSight", dependencies = c("Depends", "Imports", "Config/Needs/viz"))
```

Or without pak:

``` r

reqPkg <- c("shiny", "shinyhelper", "data.table", "Matrix", "DT", "magrittr",
            "ggplot2", "ggrepel", "hdf5r", "ggdendro", "gridExtra", "ggpubr")
newPkg <- reqPkg[!(reqPkg %in% installed.packages()[, "Package"])]
if (length(newPkg)) install.packages(newPkg)
```

Note that CellSight itself is **not** a runtime dependency. The
generated app only uses the packages above; you do not need to install
CellSight on the server.

If your app includes ATAC track plots, the host also needs the `bwtool`
and `libbeato` command-line binaries — see
[`vignette("modalities")`](https://openomics.github.io/CellSight/articles/modalities.md).
These are the one thing that will not install from CRAN, and the reason
to check a hosting platform’s constraints before committing to it.

## Running locally

From RStudio, open `shinyApp/ui.R` and click **Run App**. From the
console:

``` r

shiny::runApp("shinyApp")
```

To let others on your network reach it:

``` r

shiny::runApp("shinyApp", host = "0.0.0.0", port = 3838)
```

## shinyapps.io

Deploy the directory with **rsconnect**:

``` r

install.packages("rsconnect")
rsconnect::setAccountInfo(name = "<account>", token = "<token>", secret = "<secret>")
rsconnect::deployApp("shinyApp")
```

Two things bite here. First, shinyapps.io infers dependencies by
scanning your code, and it will not find the system binaries that ATAC
track plots need — so ATAC-enabled apps generally need a container-based
host instead. Second, the free and lower tiers have an instance memory
limit; the HDF5 design keeps CellSight apps light, but a large
`meta.rds` (millions of cells) can still exceed it.

## Shiny Server

Copy the app directory under the server’s site root and let it be served
directly:

``` bash
sudo cp -r shinyApp /srv/shiny-server/cellsight
sudo chown -R shiny:shiny /srv/shiny-server/cellsight
```

It is then available at `http://<host>:3838/cellsight/`. Make sure the
packages above are installed in a library the `shiny` user can read — a
common failure is installing them into your own `~/R` library, where the
server process cannot see them.

## Containers

Shipping the app inside an image is the most reproducible option, and
the only straightforward one when you need `bwtool`. CellSight ships
container assets under `tools/docker/CellSight/` — see
[`vignette("docker")`](https://openomics.github.io/CellSight/articles/docker.md).

The short version: build on top of an image that already has the runtime
stack, copy the app in, and expose Shiny’s port.

``` dockerfile
FROM rocker/shiny:latest

RUN install2.r --error shinyhelper data.table Matrix DT magrittr \
    ggplot2 ggrepel hdf5r ggdendro gridExtra ggpubr

COPY shinyApp /srv/shiny-server/cellsight
EXPOSE 3838
```

## Google Analytics

[`makeShinyCodes()`](https://openomics.github.io/CellSight/reference/makeShinyCodes.md)
takes a tracking ID and writes the corresponding `google-analytics.html`
into the app directory:

``` r

makeShinyCodes(
  shiny.title  = "PBMC multiomics",
  shiny.prefix = "sc1",
  shiny.dir    = "shinyApp/",
  ganalytics   = "UA-123456789-0"
)
```

Consider whether you need it before enabling it — if the app hosts
unpublished or human-subject data, adding third-party tracking to it may
not be something your data agreement permits.

## Further reading

The upstream ShinyCell2 project has more detail on cloud hosting, which
applies unchanged to CellSight apps: [Instructions on how to deploy apps
online](https://htmlpreview.github.io/?https://github.com/the-ouyang-lab/cellsight-tutorial/master/docs/cloud.html).
