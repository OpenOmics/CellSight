#!/usr/bin/env Rscript
#
# Build the package, run BiocCheck, and write a formatted summary to
# GITHUB_STEP_SUMMARY. Exits non-zero (failing the job) only when BiocCheck
# reports at least one ERROR, matching Bioconductor's minimum acceptance bar.

pkg_dir <- "CellSight"
summary_file <- Sys.getenv("GITHUB_STEP_SUMMARY", "")

fail <- function(...) {
  msg <- paste0(...)
  message("ERROR: ", msg)
  if (nzchar(summary_file)) {
    cat("## BiocCheck\n\n:x: ", msg, "\n", sep = "", file = summary_file, append = TRUE)
  }
  quit(status = 1)
}

## ---- 1. Build the tarball (fallback to --no-build-vignettes) --------------
build_log <- tempfile(fileext = ".txt")
build_status <- system2("R", c("CMD", "build", pkg_dir), stdout = build_log, stderr = build_log)
tarball <- Sys.glob("cellsight_*.tar.gz")

if (build_status != 0 || length(tarball) == 0) {
  message("Full build failed or produced no tarball; retrying with --no-build-vignettes")
  system2("R", c("CMD", "build", "--no-build-vignettes", pkg_dir), stdout = build_log, stderr = build_log)
  tarball <- Sys.glob("cellsight_*.tar.gz")
}

if (length(tarball) == 0) {
  fail("could not build a tarball even with --no-build-vignettes:\n\n```\n",
       paste(readLines(build_log), collapse = "\n"), "\n```")
}
tarball <- tarball[[1]]

## ---- 2. Run BiocCheck -------------------------------------------------------
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
}
if (!requireNamespace("BiocCheck", quietly = TRUE)) {
  BiocManager::install("BiocCheck", update = FALSE, ask = FALSE)
}

res <- tryCatch(
  BiocCheck::BiocCheck(tarball),
  error = function(e) e
)

if (inherits(res, "error")) {
  fail("BiocCheck itself errored: ", conditionMessage(res))
}

## ---- 3. Format the summary ---------------------------------------------------
counts <- res$getNum()

flatten_entry <- function(entry) {
  ## Each check's findings are a list of character vectors / strings; collapse
  ## to one block of text per check.
  parts <- unlist(entry, use.names = FALSE)
  paste(parts, collapse = "\n")
}

render_section <- function(title, emoji, entries) {
  lines <- c(paste0("### ", emoji, " ", title, " (", length(entries), ")"), "")
  if (length(entries) == 0) {
    lines <- c(lines, "_None_", "")
    return(lines)
  }
  ## Iterate by position, not by name: the same check function can report
  ## more than once, so names(entries) can repeat and `entries[[name]]`
  ## would always return just the first match.
  check_names <- names(entries)
  for (i in seq_along(entries)) {
    lines <- c(lines,
      paste0("<details><summary><code>", check_names[[i]], "</code></summary>"),
      "",
      "```",
      flatten_entry(entries[[i]]),
      "```",
      "",
      "</details>", "")
  }
  lines
}

summary_lines <- c(
  "## BiocCheck",
  "",
  paste0("Tarball: `", tarball, "`"),
  "",
  "| ERRORS | WARNINGS | NOTES |",
  "| --- | --- | --- |",
  paste0("| ", counts[["error"]], " | ", counts[["warning"]], " | ", counts[["note"]], " |"),
  "",
  render_section("Errors", ":x:", res$error),
  render_section("Warnings", ":warning:", res$warning),
  render_section("Notes", ":information_source:", res$note)
)

cat(paste(summary_lines, collapse = "\n"), file = if (nzchar(summary_file)) summary_file else stdout(), append = TRUE)
cat("\n")

if (counts[["error"]] > 0) {
  message("BiocCheck reported ", counts[["error"]], " ERROR(s).")
  quit(status = 1)
}

message("BiocCheck passed with 0 ERRORs (", counts[["warning"]], " warning(s), ",
        counts[["note"]], " note(s)).")
quit(status = 0)
