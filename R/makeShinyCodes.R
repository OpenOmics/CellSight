#' Generate code files required for shiny app
#'
#' Generate code files required for shiny app for both single-dataset and
#' multi-dataset scenarios. Specifically, two R scripts will be generated,
#' namely \code{server.R} and \code{ui.R}. Note that \code{makeShinyFiles} has
#' to be ran prior to make the necessary data files for each dataset included.
#' The prefix used in \code{makeShinyFiles} have to be then supplied in this
#' function.
#'
#' The three output files (\code{server.R}, \code{ui.R}, \code{shinyFunc.R})
#' are assembled from jinjar templates shipped under \code{inst/templates}.
#' The master templates (\code{server.R.jinja}, \code{ui.R.jinja},
#' \code{shinyFunc.R.jinja}) contain the orchestration logic - which tab blocks
#' to include for each dataset, gated on the presence of spatial / ATAC / DEG
#' data - and \code{{\% include \%}} one partial per tab block. All per-dataset
#' facts (prefix, headers, point sizes, spatial slider parameters and which
#' data types are present) are computed here in R and passed as the template
#' context.
#'
#' @param shiny.title specify the overall title for shiny app
#' @param shiny.footnotes text for shiny app footnote. When given as a list,
#'   citation can be inserted by specifying author, title, journal, volume,
#'   page, year, doi, link. See example below.
#' @param shiny.prefix specify file prefix for each dataset. Must match the
#'   prefix used in \code{makeShinyFiles}
#' @param shiny.headers specify the tab header names for each dataset. Length
#'   must match that of \code{shiny.prefix}. Note that this is ignored if
#'   there is only one dataset
#' @param shiny.dir specify directory to create the shiny app in
#' @param defPtSiz specify default point size for single cells. For example, a
#'   smaller size can be used if you have many cells in your dataset. A single
#'   value can be specified to set the point size for all datasets. Otherwise,
#'   users have to specify one value for each dataset
#' @param ganalytics Google analytics tracking ID (e.g. "UA-123456789-0")
#'
#' @return server.R and ui.R required for shiny app
#'
#' @author John F. Ouyang
#'
#' @import data.table readr
#'
#' @examples
#' \dontrun{
#' # Example citation
#' citation = list(
#'   author  = "Liu X., Ouyang J.F., Rossello F.J. et al.",
#'   title   = "",
#'   journal = "Nature",
#'   volume  = "586",
#'   page    = "101-107",
#'   year    = "2020",
#'   doi     = "10.1038/s41586-020-2734-6",
#'   link    = "https://www.nature.com/articles/s41586-020-2734-6")
#' makeShinyCodes(shiny.title = "scRNA-seq shiny app", shiny.footnotes = "",
#'                shiny.prefix = c("sc1", "sc2"), defPtSiz = c(1.25, 1.5),
#'                shiny.headers = c("dataset1", "dataset2"),
#'                shiny.dir = "shinyApp/")
#' }
#'
#' @export
makeShinyCodes <- function(
  shiny.title,
  shiny.footnotes = "",
  shiny.prefix,
  shiny.headers,
  shiny.dir,
  defPtSiz = 1.25,
  ganalytics = NA
) {
  ### Checks
  if (length(shiny.prefix) > 1) {
    if (length(shiny.prefix) != length(shiny.headers)) {
      stop("length of shiny.prefix and shiny.headers does not match!")
    }
  }
  if (length(shiny.prefix) != length(defPtSiz)) {
    defPtSiz = rep(defPtSiz[1], length(shiny.prefix))
  }
  defPtSiz2 = as.character(defPtSiz * 2)
  defPtSiz = as.character(defPtSiz)

  ### Check if files exist
  for (i in shiny.prefix) {
    if (!file.exists(paste0(shiny.dir, "/", i, "conf.rds"))) {
      stop(paste0("files missing for ", i, " dataset!"))
    }
  }

  is_single <- length(shiny.prefix) == 1

  ### Build per-dataset context. Spatial slider parameters and point-size
  ### clamping mirror the historical per-tab logic exactly; two point-size
  ### variants are exposed (ptsiz = defPtSiz, ptsiz2 = 2 * defPtSiz) as well
  ### as first-dataset variants used by the extra spatial tab in the
  ### multi-dataset layout.
  slider_for <- function(prefix) {
    meta_file <- paste0(prefix, "meta.rds")
    if (file.exists(meta_file)) {
      n_cells <- nrow(readRDS(meta_file))
    } else {
      n_cells <- 10000  # Default fallback
    }
    if (n_cells > 20000) {
      list(min = 0.1, max = 2, step = 0.05)   # fine control
    } else {
      list(min = 0.25, max = 2, step = 0.25)  # broad control
    }
  }
  clamp <- function(ptsiz, sl) max(sl$min, min(as.numeric(ptsiz), sl$max))

  # slider parameters / clamped point size for the FIRST dataset (used by the
  # additional spatial tab that the multi-dataset UI renders with defPtSiz[1])
  sl1 <- slider_for(shiny.prefix[1])
  ptsiz_val_first <- clamp(defPtSiz[1], sl1)

  datasets <- lapply(seq_along(shiny.prefix), function(i) {
    px <- shiny.prefix[i]
    has_image <- file.exists(paste0(shiny.dir, "/", px, "image.rds"))
    has_bw    <- file.exists(paste0(shiny.dir, "/", px, "bw.rds"))
    has_deg   <- file.exists(paste0(shiny.dir, "/", px, "deg.h5"))
    multislide <- FALSE
    if (has_image) {
      tmpImg <- readRDS(paste0(shiny.dir, "/", px, "image.rds"))
      multislide <- !is.null(tmpImg$slide_names) && length(tmpImg$slide_names) > 1
    }
    sl <- slider_for(px)
    list(
      prefix     = px,
      header     = if (i <= length(shiny.headers)) shiny.headers[i] else "",
      ptsiz      = defPtSiz[i],
      has_image  = has_image,
      has_bw     = has_bw,
      has_deg    = has_deg,
      multislide = multislide,
      # spatial slider (2 * defPtSiz for the primary spatial tabs)
      slider_min      = sl$min,
      slider_max      = sl$max,
      slider_step     = sl$step,
      ptsiz_val       = clamp(defPtSiz2[i], sl),
      # first-dataset variant for the extra multi-dataset spatial tab
      slider_min_first  = sl1$min,
      slider_max_first  = sl1$max,
      slider_step_first = sl1$step,
      ptsiz_val_first   = ptsiz_val_first
    )
  })

  # The historical single-dataset code gated the DEG tab on the loop variable
  # `i` left over from the load loop, i.e. the LAST prefix. Reproduce that.
  single_has_deg <- file.exists(
    paste0(shiny.dir, "/", shiny.prefix[length(shiny.prefix)], "deg.h5"))

  # Footnote context (list => structured citation, else plain text)
  is_list <- is.list(shiny.footnotes)
  fn   <- if (is_list) shiny.footnotes else list()
  text <- if (!is_list) as.character(shiny.footnotes[[1]]) else ""

  # Google-analytics header line for ui pre
  if (!is.na(ganalytics)) {
    ga <- 'tags$head(includeHTML(("google-analytics.html"))),'
  } else {
    ga <- ''
  }

  cfg <- jinjar::jinjar_config(
    variable_open = "<<", variable_close = ">>",
    loader = jinjar::path_loader(system.file("templates", package = "cellsight")))

  ctx <- list(
    datasets       = datasets,
    is_single      = is_single,
    any_bw         = any(vapply(datasets, function(d) d$has_bw, logical(1))),
    any_image      = any(vapply(datasets, function(d) d$has_image, logical(1))),
    any_deg        = any(vapply(datasets, function(d) d$has_deg, logical(1))),
    single_has_deg = single_has_deg,
    title          = shiny.title,
    ga             = ga,
    is_list        = is_list,
    fn             = fn,
    text           = text
  )

  master <- function(name) {
    jinjar::render(
      readChar(system.file("templates", name, package = "cellsight"),
               file.info(system.file("templates", name, package = "cellsight"))$size),
      !!!ctx, .config = cfg)
  }

  ### Write code for shinyFunc.R (+ copy trackplot.R when any ATAC dataset)
  readr::write_file(master("shinyFunc.R.jinja"),
                    file = paste0(shiny.dir, "/shinyFunc.R"))
  if (ctx$any_bw) {
    srcPath <- system.file("extdata", "trackplot.R", package = "cellsight")
    file.copy(srcPath, paste0(shiny.dir, "/"))
  }

  ### Copy the cellsight logo into the app's www/ dir (served at the root path;
  ### referenced top-left in ui.R via img(src = "cellsight_logo.png"))
  wwwDir <- paste0(shiny.dir, "/www")
  if (!dir.exists(wwwDir)) dir.create(wwwDir)
  file.copy(system.file("www", "cellsight_logo.png", package = "cellsight"),
            paste0(wwwDir, "/"), overwrite = TRUE)

  ### Write code for server.R and ui.R
  readr::write_file(master("server.R.jinja"), file = paste0(shiny.dir, "/server.R"))
  readr::write_file(master("ui.R.jinja"),     file = paste0(shiny.dir, "/ui.R"))

  ### Write code for google-analytics.html
  if (!is.na(ganalytics)) {
    ga_html <- jinjar::render(
      r"(<!-- Global site tag (gtag.js) - Google Analytics -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=<< gaID >>"></script>
  <script>
  window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());

gtag('config', '<< gaID >>');
</script> )",
      gaID = ganalytics, .config = cfg)
    readr::write_file(ga_html, file = paste0(shiny.dir, "/google-analytics.html"))
  }

  ### Tidy the generated R with styler.
  # The templates are jinjar fragments assembled at several nesting depths, so
  # their indentation cannot be correct in every rendered context. styler
  # re-formats the final, fully-assembled programs (indentation, spacing, etc.)
  # so the code users actually run is clean and lint-tidy. It is formatting-only
  # (no behaviour change); if styler is unavailable or errors, the generated
  # files remain valid R and are simply left un-styled.
  if (requireNamespace("styler", quietly = TRUE)) {
    for (f in c("server.R", "ui.R", "shinyFunc.R")) {
      fp <- paste0(shiny.dir, "/", f)
      if (file.exists(fp)) {
        try(
          invisible(utils::capture.output(
            suppressMessages(styler::style_file(fp)))),
          silent = TRUE)
      }
    }
  }
}
