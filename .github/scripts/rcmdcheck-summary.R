#!/usr/bin/env Rscript
#
# Run R CMD check --as-cran (via rcmdcheck, which also handles the build step)
# and write a formatted summary to GITHUB_STEP_SUMMARY. Exits non-zero (failing
# the job) only when the check reports at least one ERROR.

pkg_dir <- "."
summary_file <- Sys.getenv("GITHUB_STEP_SUMMARY", "")

fail <- function(...) {
  msg <- paste0(...)
  message("ERROR: ", msg)
  if (nzchar(summary_file)) {
    cat("## R CMD check --as-cran\n\n:x: ", msg, "\n", sep = "", file = summary_file, append = TRUE)
  }
  quit(status = 1)
}

if (!requireNamespace("rcmdcheck", quietly = TRUE)) {
  install.packages("rcmdcheck", repos = "https://cloud.r-project.org")
}

Sys.setenv("_R_CHECK_FORCE_SUGGESTS_" = "false")

res <- tryCatch(
  rcmdcheck::rcmdcheck(
    pkg_dir,
    args = c("--as-cran"),
    error_on = "never",
    quiet = TRUE
  ),
  error = function(e) e
)

if (inherits(res, "error")) {
  ## rcmdcheck's own build-failure condition carries no detail (just "Build
  ## process failed"); re-run the build directly so the summary shows the
  ## actual R CMD build log instead of a one-line message.
  build_log <- tempfile(fileext = ".txt")
  system2("R", c("CMD", "build", pkg_dir), stdout = build_log, stderr = build_log)
  fail("R CMD build/check itself errored before producing a report: ",
       conditionMessage(res), "\n\n```\n",
       paste(readLines(build_log), collapse = "\n"), "\n```")
}

render_section <- function(title, emoji, items) {
  lines <- c(paste0("### ", emoji, " ", title, " (", length(items), ")"), "")
  if (length(items) == 0) {
    lines <- c(lines, "_None_", "")
    return(lines)
  }
  for (item in items) {
    lines <- c(lines, "```", item, "```", "")
  }
  lines
}

summary_lines <- c(
  "## R CMD check --as-cran",
  "",
  paste0("Package: `", res$package, "` ", res$version),
  "",
  "| ERRORS | WARNINGS | NOTES |",
  "| --- | --- | --- |",
  paste0("| ", length(res$errors), " | ", length(res$warnings), " | ", length(res$notes), " |"),
  "",
  render_section("Errors", ":x:", res$errors),
  render_section("Warnings", ":warning:", res$warnings),
  render_section("Notes", ":information_source:", res$notes)
)

cat(paste(summary_lines, collapse = "\n"), file = if (nzchar(summary_file)) summary_file else stdout(), append = TRUE)
cat("\n")

if (length(res$errors) > 0) {
  message("R CMD check reported ", length(res$errors), " ERROR(s).")
  quit(status = 1)
}

message("R CMD check passed with 0 ERRORs (", length(res$warnings), " warning(s), ",
        length(res$notes), " note(s)).")
quit(status = 0)
