# CellSight Docker Builder Scripts

This folder contains rebranded builder/container scripts migrated from the legacy
`ShinyCell2` tooling bundle at `/data/OpenOmics/dev/cellsight/ShinyCell2`.

## What was converted

- `build_shinycell.R` → `build_cellsight.R`
- GitHub install target: `OpenOmics/ShinyCell2` → `OpenOmics/CellSight`
- User-facing/help/log strings: `ShinyCell2`/`ShinyCell` → `CellSight`
- Docker entry script path updated to `/usr/bin/build_cellsight.R`

## Conversion comments reviewed

During migration, conversion-related comments were preserved and reworded where
needed for accuracy (for example, references to CellSight-supported assays,
CellSight config generation, and CellSight output file assumptions).

## Files

- `Dockerfile`: Container definition for building and running CellSight app generation workflows.
- `build_cellsight.R`: Main CLI to generate CellSight files/codes from a Seurat RDS.
- `seurat_inspector.R`: Utility to inspect Seurat object structure before app generation.
- `ingest_10x.R`: Utility to preprocess 10x Visium HD into Seurat RDS.
- `environment-build.yml` / `environment-viz.yml`: conda environments (`cs-build` for building apps, `cs-viz` for serving them).
- `env_tools.R`: helper that tops up a conda R env with CRAN/GitHub packages and verifies they load.
- `run_app.R`: serves a built app (wrapped as `run_cellsight_app` in the image).
- `Dockerfile.rocker` / `install_packages.R`: previous rocker/shiny-based build, kept for reference.
- `git_installs.sh`: Installs external native trackplot dependencies (`libbeato`, `bwtool`).
