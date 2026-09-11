# Using the Docker image

CellSight ships container assets under `tools/docker/CellSight/`. The
image bundles the full build stack — Seurat, HDF5, and the
`libbeato`/`bwtool` binaries that ATAC track plots need — behind a
command-line interface, so you can build an app without setting up an R
environment.

Reach for it when you want reproducibility, when you are building on a
cluster or CI runner, or specifically when you need ATAC track plots,
since those native dependencies are the most tedious part of a manual
install.

## What is in the image

Built on `rocker/shiny:4.4.3`, with:

| file | role |
|----|----|
| `Dockerfile` | image definition |
| `install_packages.R` | CRAN / Bioconductor dependency bootstrap |
| `git_installs.sh` | builds the native `libbeato` and `bwtool` trackplot binaries |
| `build_cellsight.R` | the main CLI: Seurat RDS in, app out |
| `seurat_inspector.R` | audits a Seurat object’s structure |
| `ingest_10x.R` | preprocesses a 10x Visium HD output directory into a Seurat RDS |

The Dockerfile installs CellSight itself from GitHub
(`remotes::install_github("OpenOmics/CellSight")`) and places all three
scripts on the `PATH` at `/usr/bin/`, marked executable. Each carries a
`#!/usr/bin/env Rscript` shebang, so you can invoke them either way:

``` bash
docker run --rm cellsight:latest build_cellsight.R --help
docker run --rm cellsight:latest Rscript /usr/bin/build_cellsight.R --help
```

The examples below use the explicit `Rscript` form.

## Build

``` bash
cd CellSight/tools/docker/CellSight
docker build -t cellsight:latest .
```

Expect this to take a while: it compiles the native trackplot
dependencies and installs the whole Seurat stack from source.

## Publish

Tag and push to whichever registry you use — GHCR shown here. Replace
`<org-or-user>` with your namespace:

``` bash
docker tag cellsight:latest ghcr.io/<org-or-user>/cellsight:latest
docker push ghcr.io/<org-or-user>/cellsight:latest
```

Push a version tag alongside `latest` so a deployed app can be traced
back to the image that built it:

``` bash
docker tag cellsight:latest ghcr.io/<org-or-user>/cellsight:v0.0.1
docker push ghcr.io/<org-or-user>/cellsight:v0.0.1
```

## Build an app with `build_cellsight.R`

The CLI wraps
[`createConfig()`](https://openomics.github.io/CellSight/reference/createConfig.md),
[`makeShinyFiles()`](https://openomics.github.io/CellSight/reference/makeShinyFiles.md)
and
[`makeShinyCodes()`](https://openomics.github.io/CellSight/reference/makeShinyCodes.md).
Three arguments are required — the object, the output directory, and the
project name that becomes the app title:

``` bash
docker pull ghcr.io/<org-or-user>/cellsight:latest

docker run --rm -it \
  -v /path/to/input:/input \
  -v /path/to/output:/output \
  ghcr.io/<org-or-user>/cellsight:latest \
  Rscript /usr/bin/build_cellsight.R \
    --obj /input/seurat_obj.rds \
    --outdir /output \
    --proj "My CellSight App"
```

The remaining options:

| flag | effect |
|----|----|
| `-j`, `--obj` | **required.** Seurat object saved with [`saveRDS()`](https://rdrr.io/r/base/readRDS.html) |
| `-o`, `--outdir` | **required.** where the app is written |
| `--proj` | **required.** project name, used as the app title |
| `-a`, `--assay` | comma-delimited assays to keep, e.g. `RNA,spatial`; all others are dropped |
| `--defred` | default reduction, which must exist in the object |
| `--markers` | plain-text file of marker genes, one per line |
| `--cluster_labels` | metadata column holding cluster labels |
| `--rmmeta` | comma-delimited metadata columns to drop before building |
| `-l`, `--maxlevels` | maximum categories per categorical metadata |
| `--filesonly` | run [`makeShinyFiles()`](https://openomics.github.io/CellSight/reference/makeShinyFiles.md) only |
| `--codesonly` | run [`makeShinyCodes()`](https://openomics.github.io/CellSight/reference/makeShinyCodes.md) only |
| `--silent` | suppress verbose output |

`--markers` and `--cluster_labels` are all-or-nothing: supplying one
without the other is a fatal error.

`--defred` expects the reduction’s components to be named with a
trailing `1` and `2` — for `--defred UMAP`, the object needs `UMAP1` and
`UMAP2`.

`--filesonly` and `--codesonly` split the two build stages, which is
what you want on a cluster: run the slow data step once as a batch job,
then re-run the fast code step whenever you want to change the title or
point sizes.

## Inspect before you build

`build_cellsight.R` fails on objects missing the reductions or metadata
it expects, and the error arrives after the slow part.
`seurat_inspector.R` prints an audit — assays, reductions, metadata
columns, cluster summary, and spatial image/slide structure — so you can
catch those first. It takes a path as a positional argument:

``` bash
docker run --rm -it \
  -v /path/to/output:/output \
  ghcr.io/<org-or-user>/cellsight:latest \
  Rscript /usr/bin/seurat_inspector.R /output/visium_hd_sample_16um.rds
```

Worth doing routinely for spatial data, where it reports the slide
structure that drives the app’s slide selector — see
[`vignette("modalities")`](https://openomics.github.io/CellSight/articles/modalities.md).

## Start from raw 10x Visium HD output

`ingest_10x.R` takes a 10x output directory through QC, normalisation,
PCA, clustering and UMAP, and writes a Seurat `.rds` plus QC and summary
plots — a ready-to-build object:

``` bash
docker run --rm -it \
  -v /path/to/10x_output:/input \
  -v /path/to/output:/output \
  ghcr.io/<org-or-user>/cellsight:latest \
  Rscript /usr/bin/ingest_10x.R \
    --data-dir /input \
    --outdir /output
```

It exposes the pipeline’s parameters, so you can tune the run without
editing the script: `--bin-size` and `--slice` for which Visium HD
binning and slice to read, `--assay`, the QC thresholds `--min-features`
/ `--max-features` / `--max-pct-mt`, and the analysis parameters
`--nfeatures-hvg`, `--npcs` and `--resolution`. `--output-rds` names the
output object and `--memory-gb` caps memory use.

The defaults are a reasonable starting point, not a substitute for
looking at the QC plots it writes — clustering `--resolution` in
particular is a choice about your data, and the value that produces
biologically sensible clusters is not knowable in advance.

## A full run

Ingest, inspect, then build:

``` bash
IMG=ghcr.io/<org-or-user>/cellsight:latest
docker run --rm -v /data/visium:/input -v /data/out:/output $IMG \
  Rscript /usr/bin/ingest_10x.R --data-dir /input --outdir /output --bin-size 16

docker run --rm -v /data/out:/output $IMG \
  Rscript /usr/bin/seurat_inspector.R /output/visium_hd_sample_16um.rds

docker run --rm -v /data/out:/output $IMG \
  Rscript /usr/bin/build_cellsight.R \
    --obj /output/visium_hd_sample_16um.rds \
    --outdir /output/shinyApp \
    --proj "Visium HD 16um" \
    --defred UMAP
```

`/data/out/shinyApp` is then a complete app directory — see
[`vignette("deployment")`](https://openomics.github.io/CellSight/articles/deployment.md)
for serving it.
