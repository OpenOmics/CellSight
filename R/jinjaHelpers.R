#' jinjar configuration used by all cellsight code writers
#'
#' Uses \verb{<<} and \verb{>>} for variable interpolation so that the many
#' literal curly braces in the generated Shiny/ggplot code pass through
#' untouched. Block and comment delimiters keep the jinjar defaults; neither
#' of those sequences occurs in the generated code.
#'
#' @return a \code{jinjar_config} object
#' @rdname scJinjaCfg
#' @export scJinjaCfg
#'
scJinjaCfg <- function() {
  jinjar::jinjar_config(variable_open = "<<", variable_close = ">>")
}

#' Dedent a template block
#'
#' Removes the common leading indentation from a multi-line string: the first
#' line is dropped if it is only indentation, the minimum indent shared by the
#' remaining lines is stripped, and a single trailing whitespace-only line is
#' removed. This is a self-contained reimplementation of the dedenting that
#' \code{glue::glue()} applied to these templates, kept so the code writers do
#' not depend on \pkg{glue}. Operates on ASCII input.
#'
#' @param x a character vector of template blocks
#'
#' @return the dedented character vector
#' @rdname scTrim
#' @export scTrim
#'
scTrim <- function(x) {
  if (length(x) == 0L || !any(grepl("\n", x, fixed = TRUE))) {
    return(x)
  }
  vapply(x, function(xx) {
    cs <- strsplit(xx, "", fixed = TRUE)[[1]]
    n <- length(cs)
    is_ws <- function(k) k >= 1L && k <= n && (cs[k] == " " || cs[k] == "\t")

    ## skip leading blanks on the first line
    start <- 1L
    while (start <= n && is_ws(start)) start <- start + 1L
    new_line <- FALSE
    ## skip the first newline
    if (start <= n && cs[start] == "\n") {
      new_line <- TRUE
      start <- start + 1L
    }
    i <- start
    ## if the first line had content, ignore it entirely
    if (!new_line) {
      while (i <= n && cs[i] != "\n") i <- i + 1L
      new_line <- TRUE
    }

    ## find the minimum indent across the remaining lines
    indent <- 0L
    min_indent <- .Machine$integer.max
    while (i <= n) {
      if (cs[i] == "\n") {
        new_line <- TRUE
        indent <- 0L
      } else if (new_line) {
        if (cs[i] == " " || cs[i] == "\t") {
          indent <- indent + 1L
        } else {
          if (indent < min_indent) min_indent <- indent
          indent <- 0L
          new_line <- FALSE
        }
      }
      i <- i + 1L
    }
    if (n >= 1L && cs[n] != "\n" && new_line && indent < min_indent) {
      min_indent <- indent
    }
    ## no content line found (body is all blanks / newlines): nothing to dedent
    if (min_indent == .Machine$integer.max) min_indent <- 0L

    ## copy, removing min_indent characters from each new line
    new_line <- TRUE
    i <- start
    out <- character(n)
    j <- 0L
    while (i <= n) {
      if (cs[i] == "\n") {
        new_line <- TRUE
      } else if (cs[i] == "\\" && i + 1L <= n && cs[i + 1L] == "\n") {
        new_line <- TRUE
        i <- i + 2L
        next
      } else if (new_line) {
        skipped <- 0L
        while (i + skipped <= n &&
               (cs[i + skipped] == "\t" || cs[i + skipped] == " ")) {
          skipped <- skipped + 1L
        }
        nxt <- i + skipped
        if (nxt <= n && cs[nxt] == "\n" && skipped < min_indent) {
          ## whitespace-only line shorter than min_indent: keep it verbatim
          if (skipped > 0L) {
            out[(j + 1L):(j + skipped)] <- cs[i:(i + skipped - 1L)]
            j <- j + skipped
          }
          i <- i + skipped
        } else if (i + min_indent <= n && (cs[i] == " " || cs[i] == "\t")) {
          i <- i + min_indent
        }
        new_line <- FALSE
        next
      }
      j <- j + 1L
      out[j] <- cs[i]
      i <- i + 1L
    }

    ## strip trailing whitespace back to the first preceding newline; char_at()
    ## returns "" (the C NUL sentinel) for the past-the-end slot at p == j
    char_at <- function(p) if (p >= j) "" else out[p + 1L]
    end <- j
    p <- j
    while (p > 0L) {
      ch <- char_at(p)
      if (ch == "\n") {
        end <- p
        break
      } else if (ch == "" || ch == " " || ch == "\t") {
        p <- p - 1L
      } else {
        break
      }
    }
    if (end <= 0L) "" else paste0(out[seq_len(end)], collapse = "")
  }, character(1), USE.NAMES = FALSE)
}

