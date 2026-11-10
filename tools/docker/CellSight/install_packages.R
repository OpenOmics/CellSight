#!/usr/bin/env Rscript

# Minimal bootstrap. CellSight's own R dependencies (data.table, Seurat,
# shiny, DT, ggpubr, Signac, BiocFileCache, ...) are resolved from the
# package DESCRIPTION when CellSight is installed from GitHub (see the
# Dockerfile), so they are intentionally not listed here.

# Posit Package Manager serves prebuilt Linux binaries (Ubuntu 22.04 "jammy"),
# which avoids long source compiles. The user agent must be set for R to be
# offered binaries.
cran_repo <- "https://packagemanager.posit.co/cran/__linux__/jammy/latest"
options(
  repos = c(CRAN = cran_repo),
  HTTPUserAgent = sprintf(
    "R/%s R (%s)", getRversion(),
    paste(getRversion(), R.version$platform, R.version$arch, R.version$os)
  )
)
use_ncpus <- max(parallel::detectCores() - 2, 2)

# Upgrade stale base-image packages first, so later installs never load an
# old copy (e.g. fs 1.6.5 vs >= 2.1.0 required).
install.packages(
  c("fs", "cli", "rlang", "vctrs", "glue", "pkgload"),
  repos = cran_repo
)

# Tools needed by the install itself and by the container's CLI scripts
# (build_cellsight.R, ingest_10x.R, seurat_inspector.R).
bootstrap <- c("remotes", "BiocManager", "argparse", "optparse")
install.packages(
  setdiff(bootstrap, rownames(installed.packages())),
  Ncpus = use_ncpus,
  repos = cran_repo
)

missing <- setdiff(bootstrap, rownames(installed.packages()))
if (length(missing) > 0) {
  stop("Bootstrap install failed for: ", paste(missing, collapse = ", "))
}
