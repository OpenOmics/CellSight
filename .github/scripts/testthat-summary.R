#!/usr/bin/env Rscript
#
# Run the package's testthat suite (tests/testthat/) directly, tally
# pass/fail/error/skip across every expectation, and write a formatted
# summary to GITHUB_STEP_SUMMARY. Exits non-zero (failing the job) only when
# at least one expectation failed or errored.

tests_dir <- "tests/testthat"
summary_file <- Sys.getenv("GITHUB_STEP_SUMMARY", "")

fail <- function(...) {
  msg <- paste0(...)
  message("ERROR: ", msg)
  if (nzchar(summary_file)) {
    cat("## testthat\n\n:x: ", msg, "\n", sep = "", file = summary_file, append = TRUE)
  }
  quit(status = 1)
}

if (!requireNamespace("testthat", quietly = TRUE)) {
  install.packages("testthat", repos = "https://cloud.r-project.org")
}
if (!requireNamespace("cellsight", quietly = TRUE)) {
  fail("cellsight is not installed; install it before running this script.")
}

library(testthat)

res <- tryCatch(
  test_dir(tests_dir, package = "cellsight", reporter = "silent", stop_on_failure = FALSE),
  error = function(e) e
)

if (inherits(res, "error")) {
  fail("testthat::test_dir() itself errored before producing results: ",
       conditionMessage(res))
}

## ---- Tally every expectation across every test_that() block --------------
n_pass <- 0L
n_fail <- 0L
n_error <- 0L
n_skip <- 0L
issues <- list()  # failing / erroring expectations
skips <- list()   # skipped test_that() blocks

for (block in res) {
  for (e in block$results) {
    cls <- class(e)
    item <- list(file = block$file, test = block$test, message = conditionMessage(e))
    if ("expectation_success" %in% cls) {
      n_pass <- n_pass + 1L
    } else if ("expectation_failure" %in% cls) {
      n_fail <- n_fail + 1L
      issues[[length(issues) + 1L]] <- item
    } else if ("expectation_error" %in% cls) {
      n_error <- n_error + 1L
      issues[[length(issues) + 1L]] <- item
    } else if ("expectation_skip" %in% cls) {
      n_skip <- n_skip + 1L
      skips[[length(skips) + 1L]] <- item
    }
  }
}

n_total <- n_pass + n_fail + n_error + n_skip

render_section <- function(title, emoji, items) {
  lines <- c(paste0("### ", emoji, " ", title, " (", length(items), ")"), "")
  if (length(items) == 0) {
    lines <- c(lines, "_None_", "")
    return(lines)
  }
  for (item in items) {
    lines <- c(lines,
      paste0("<details><summary><code>", item$file, "</code> — ", item$test, "</summary>"),
      "",
      "```",
      item$message,
      "```",
      "",
      "</details>", "")
  }
  lines
}

summary_lines <- c(
  "## testthat",
  "",
  paste0("Ran ", n_total, " expectation(s) across ", length(res), " test(s)."),
  "",
  "| PASS | FAIL | ERROR | SKIP |",
  "| --- | --- | --- | --- |",
  paste0("| ", n_pass, " | ", n_fail, " | ", n_error, " | ", n_skip, " |"),
  "",
  render_section("Failures / Errors", ":x:", issues),
  render_section("Skipped", ":fast_forward:", skips)
)

cat(paste(summary_lines, collapse = "\n"),
    file = if (nzchar(summary_file)) summary_file else stdout(), append = TRUE)
cat("\n")

if (n_fail > 0 || n_error > 0) {
  message("testthat reported ", n_fail, " failure(s) and ", n_error, " error(s).")
  quit(status = 1)
}

message("testthat passed: ", n_pass, " expectation(s) OK (", n_skip, " skipped).")
quit(status = 0)
