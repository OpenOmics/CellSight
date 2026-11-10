#!/usr/bin/env Rscript
# Helper used by the Dockerfile to top up a conda R environment.
# Run via:  micromamba run -n <env> Rscript env_tools.R key=value ...
#
# Keys (comma-separated package lists):
#   required=       CRAN packages to install if missing; error on failure
#   optional=       CRAN packages to install if missing; warn on failure
#   github=         GitHub repos (user/repo) to install; error on failure
#   github_optional= GitHub repos to install; warn on failure
#   check=          packages that must load (requireNamespace) or the script errors
#
# Key=value arguments (not -e) avoid shell/Rscript quoting problems.

args <- commandArgs(trailingOnly = TRUE)
kv <- strsplit(args, "=", fixed = TRUE)
opts <- setNames(
  lapply(kv, function(x) strsplit(paste(x[-1], collapse = "="), ",", fixed = TRUE)[[1]]),
  vapply(kv, `[`, "", 1)
)
get <- function(k) if (is.null(opts[[k]])) character(0) else opts[[k]]

options(repos = c(CRAN = "https://cloud.r-project.org"))
ncpus <- max(parallel::detectCores() - 2, 1)

cran_install <- function(pkgs, fatal) {
  for (p in pkgs) {
    if (requireNamespace(p, quietly = TRUE)) next
    try(install.packages(p, Ncpus = ncpus), silent = FALSE)
    if (!requireNamespace(p, quietly = TRUE)) {
      msg <- paste("CRAN package failed to install/load:", p)
      if (fatal) stop(msg) else warning(msg, call. = FALSE)
    }
  }
}

gh_install <- function(repos, fatal) {
  for (r in repos) {
    ok <- tryCatch({
      remotes::install_github(r, dependencies = FALSE, upgrade = "never")
      TRUE
    }, error = function(e) {
      message("install_github(", r, ") failed: ", conditionMessage(e))
      FALSE
    })
    if (!ok) {
      msg <- paste("GitHub package failed to install:", r)
      if (fatal) stop(msg) else warning(msg, call. = FALSE)
    }
  }
}

cran_install(get("required"), fatal = TRUE)
cran_install(get("optional"), fatal = FALSE)
gh_install(get("github"), fatal = TRUE)
if (length(get("github_optional")) > 0) {
  # ArchR-style packages pull Bioconductor deps
  options(repos = BiocManager::repositories())
  gh_install(get("github_optional"), fatal = FALSE)
}

chk <- get("check")
if (length(chk) > 0) {
  ok <- vapply(chk, function(p) requireNamespace(p, quietly = TRUE), logical(1))
  if (!all(ok)) {
    cat("FATAL: required R package(s) missing or failing to load:\n", file = stderr())
    cat(paste0("  - ", chk[!ok]), sep = "\n", file = stderr())
    quit(status = 1, save = "no")
  }
  cat(sprintf("OK: all %d required R packages load.\n", length(chk)))
}
