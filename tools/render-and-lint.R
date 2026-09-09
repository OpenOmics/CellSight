#!/usr/bin/env Rscript
## Render the jinjar code templates to a real shiny app, then lint the RENDERED
## R files (server.R, ui.R, shinyFunc.R).
##
## Why render first: the templates in inst/templates are jinjar fragments — they
## contain << d.prefix >> / {% %} tokens and are only valid R once makeShinyCodes()
## assembles them, at varying nesting depths. Linting the fragments directly is
## meaningless; linting the assembled program checks the code users actually run.
## makeShinyCodes() runs styler on the generated files, so their layout/indentation
## is already normalized — this script enforces that it stays lint-clean.
##
## Exit status (STRICT — suitable as a CI gate):
##   * non-zero if a template fails to render,
##   * non-zero if any generated file is not valid R,
##   * non-zero if the linter reports ANY finding.
##
## Usage: Rscript tools/render-and-lint.R

suppressMessages({
  library(cellsight)
  library(lintr)
})

fail <- function(...) { message("ERROR: ", ...); quit(status = 1) }

## ---- 1. Render a fully-featured app (exercises every template) --------------
app_dir <- tempfile("shinycell_render_")
dir.create(app_dir)

## Two datasets exercise the multi-dataset (navbarMenu) layout; the first carries
## spatial (multi-slide) + ATAC + DEG data so every tab template renders.
prefixes <- c("sc1", "sc2")
for (px in prefixes) {
  saveRDS(data.frame(cellID = paste0("c", 1:5)), file.path(app_dir, paste0(px, "conf.rds")))
  saveRDS(data.frame(cellID = paste0("c", 1:5)), file.path(app_dir, paste0(px, "meta.rds")))
}
saveRDS(list(slide_names = c("A", "B"), slide_display_names = c("A", "B")),
        file.path(app_dir, "sc1image.rds"))
saveRDS(list(genome = "hg38"), file.path(app_dir, "sc1bw.rds"))
writeLines("x", file.path(app_dir, "sc1deg.h5"))

ok <- tryCatch({
  makeShinyCodes(
    shiny.title     = "Lint render",
    shiny.footnotes = list(author = "A", year = "2024"),
    shiny.prefix    = prefixes,
    shiny.headers   = c("Dataset 1", "Dataset 2"),
    shiny.dir       = app_dir,
    defPtSiz        = c(1.25, 1.5),
    ganalytics      = "UA-000000-0"
  )
  TRUE
}, error = function(e) { message(conditionMessage(e)); FALSE })
if (!ok) fail("makeShinyCodes() failed to render the templates.")

rendered <- file.path(app_dir, c("server.R", "ui.R", "shinyFunc.R"))
miss <- rendered[!file.exists(rendered)]
if (length(miss)) fail("render produced no ", paste(basename(miss), collapse = ", "))

## ---- 2. Hard check: rendered files must be valid R --------------------------
for (f in rendered) {
  e <- tryCatch({ parse(f); NULL }, error = function(e) conditionMessage(e))
  if (!is.null(e)) fail(basename(f), " does not parse: ", e)
}

## ---- 3. Lint the (already styler-formatted) rendered files ------------------
## Layout is owned by styler (run inside makeShinyCodes), so indentation_linter
## is off to avoid the well-known styler/lintr hanging-indent disagreement. The
## other disabled linters reflect the upstream ShinyCell house style / generated
## code (= assignment, camelCase & dotted names, long UI lines, explanatory
## commented snippets, `&`/`|` in scalar conditions, explicit return()), plus the
## non-standard-evaluation symbols (data.table columns, ggplot aes).
cfg <- lintr::linters_with_defaults(
  indentation_linter    = NULL,
  assignment_linter     = NULL,
  object_name_linter    = NULL,
  object_usage_linter   = NULL,
  line_length_linter    = NULL,
  commented_code_linter = NULL,
  vector_logic_linter   = NULL,
  return_linter         = NULL
)

total <- 0L
for (f in rendered) {
  lints <- lint(f, linters = cfg)
  total <- total + length(lints)
  cat(sprintf("== %s: %d lint(s) ==\n", basename(f), length(lints)))
  if (length(lints)) print(lints)
}

if (total > 0L) fail(total, " lint(s) in the rendered app (see above).")
cat("\nOK: templates render, generated R parses, and is lint-clean.\n")
