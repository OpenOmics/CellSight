#!/usr/bin/env Rscript
# Serve a built CellSight app from the cs-viz environment.
# Usage: run_cellsight_app APP_DIR [PORT] [HOST]
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: run_cellsight_app APP_DIR [PORT] [HOST]")
app <- normalizePath(args[1], mustWork = TRUE)
port <- if (length(args) >= 2) as.integer(args[2]) else 3838L
host <- if (length(args) >= 3) args[3] else "0.0.0.0"
for (f in c("ui.R", "server.R")) {
  if (!file.exists(file.path(app, f))) stop(f, " not found in ", app)
}
shiny::runApp(app, port = port, host = host, launch.browser = FALSE)
