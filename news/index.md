# Changelog

## cellsight 0.0.1

First release of CellSight, derived from
[ShinyCell2](https://github.com/the-ouyang-lab/ShinyCell2) under
GPL-3.0. See
[`vignette("credits")`](https://openomics.github.io/CellSight/articles/credits.md)
for upstream attribution.

### App generation

- [`makeShinyFiles()`](https://openomics.github.io/CellSight/reference/makeShinyFiles.md)
  dispatches on the object it is given, so a single call writes every
  modality present: gene expression for Seurat objects and `.h5ad`
  files, spatial data when `obj@images` is populated, ATAC coverage when
  a `peaks` assay and `bigWigGroup` are supplied, and a DEG page when
  `precomputed.deg` and `clusters` are given. `ArchRProject` inputs
  route to
  [`makeShinyFilesATACarchr()`](https://openomics.github.io/CellSight/reference/makeShinyFilesATACarchr.md).

- [`makeShinyCodes()`](https://openomics.github.io/CellSight/reference/makeShinyCodes.md)
  assembles `server.R`, `ui.R` and `shinyFunc.R` from
  [jinjar](https://davidchall.github.io/jinjar/) templates shipped in
  `inst/templates`, replacing the previous hand-written `wr*` code
  writers. The generated files are run through
  [styler](https://styler.r-lib.org) so their layout is consistent
  regardless of how the template fragments were indented. See
  [`vignette("templates")`](https://openomics.github.io/CellSight/articles/templates.md)
  for the template map.

- Both single-dataset and multi-dataset apps are supported;
  multi-dataset apps group each dataset’s tabs under a per-dataset
  dropdown header.

- `.h5ad` (AnnData / Scanpy) files are accepted wherever an object is,
  read via **reticulate**.
  [`makeH5fromAnndata()`](https://openomics.github.io/CellSight/reference/makeH5fromAnndata.md)
  writes the expression matrix — reading `h5ad.X` by default, or a named
  entry of `h5ad.layers`.

### Configuration

- [`createConfig()`](https://openomics.github.io/CellSight/reference/createConfig.md)
  accepts Seurat objects and `.h5ad` file paths, and the
  [`addMeta()`](https://openomics.github.io/CellSight/reference/addMeta.md)
  /
  [`delMeta()`](https://openomics.github.io/CellSight/reference/delMeta.md)
  /
  [`modMetaName()`](https://openomics.github.io/CellSight/reference/modMetaName.md)
  /
  [`modLabels()`](https://openomics.github.io/CellSight/reference/modLabels.md)
  /
  [`modColours()`](https://openomics.github.io/CellSight/reference/modColours.md)
  /
  [`modDefault()`](https://openomics.github.io/CellSight/reference/modDefault.md)
  /
  [`reorderMeta()`](https://openomics.github.io/CellSight/reference/reorderMeta.md)
  helpers refine the resulting config.
  [`checkConfig()`](https://openomics.github.io/CellSight/reference/checkConfig.md)
  validates a config against its object before you build.

### Tooling

- `tools/render-and-lint.R` renders a fully-featured app from the
  templates and lints the generated R, and runs on every pull request.

- Container assets under `tools/docker/CellSight/`, including the
  `ingest_10x.R` and `seurat_inspector.R` helper scripts. See
  [`vignette("docker")`](https://openomics.github.io/CellSight/articles/docker.md).

- A bundled VS Code syntax extension for `*.R.jinja` files under
  `inst/extdata/vscode-rjinja/`.
