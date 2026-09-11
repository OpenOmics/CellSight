#' Resolve a bundled refGene GTF via a cached remote download
#'
#' CellSight ships four large \code{refGene} gene-annotation GTF files
#' (\code{hg19}, \code{hg38}, \code{mm9}, \code{mm10}) that are used to build the
#' gene index for ATAC track plots. To keep the installed package small, these
#' files are hosted as release assets and downloaded on demand the first time
#' they are needed. Downloads are cached with \pkg{BiocFileCache} so each file
#' is fetched only once and reused on subsequent calls.
#'
#' @param scGenome character scalar naming the genome build. One of
#'   \code{"hg19"}, \code{"hg38"}, \code{"mm9"}, \code{"mm10"}.
#' @param cache optional \code{BiocFileCache} object. Defaults to a persistent
#'   package-specific cache under \code{tools::R_user_dir("cellsight", "cache")}.
#' @param verbose logical; emit a message when a file is downloaded. Default
#'   \code{TRUE}.
#'
#' @return A length-one character vector giving the local filesystem path to the
#'   (cached) \code{*.refGene.gtf.gz} file.
#'
#' @details
#' The remote sources are pinned to the \code{datav1.0.0} data release of the
#' CellSight repository:
#' \itemize{
#'   \item \code{hg19}, \code{hg38}: GitHub release assets
#'   \item \code{mm9}, \code{mm10}: GitHub user-attachment assets
#' }
#'
#' @examples
#' \dontrun{
#' gtf <- getRefGeneGTF("hg38")
#' file.exists(gtf)
#' }
#'
#' @export
getRefGeneGTF <- function(scGenome, cache = refGeneCache(), verbose = TRUE) {
  urls <- refGeneURLs()
  scGenome <- as.character(scGenome)[1]
  if (!scGenome %in% names(urls)) {
    stop("No refGene GTF is available for genome '", scGenome, "'. ",
         "Supported genomes: ", paste(names(urls), collapse = ", "), ".")
  }

  url <- urls[[scGenome]]
  rname <- paste0(scGenome, ".refGene.gtf.gz")

  hits <- BiocFileCache::bfcquery(cache, rname, field = "rname", exact = TRUE)
  if (nrow(hits) == 0L) {
    if (verbose) {
      message("Downloading ", rname, " (one-time, will be cached) ...")
    }
    path <- BiocFileCache::bfcadd(
      cache, rname = rname, fpath = url, download = TRUE, rtype = "web")
    path <- unname(path)
  } else {
    path <- hits$rpath[1]
    # Ensure the file is actually present on disk; re-download if missing.
    if (!file.exists(path)) {
      path <- BiocFileCache::bfcdownload(cache, rid = hits$rid[1], ask = FALSE)
      path <- unname(path)
    }
  }

  path
}

#' Persistent BiocFileCache for CellSight reference data
#'
#' Returns (creating if necessary) the package-specific on-disk cache used to
#' store downloaded reference annotation files.
#'
#' @param cache.dir directory in which to store the cache. Defaults to
#'   \code{tools::R_user_dir("cellsight", "cache")}.
#'
#' @return A \code{BiocFileCache} object.
#'
#' @export
refGeneCache <- function(cache.dir = tools::R_user_dir("cellsight", "cache")) {
  if (!requireNamespace("BiocFileCache", quietly = TRUE)) {
    stop("Package 'BiocFileCache' is required to download reference GTF files. ",
         "Install it with BiocManager::install('BiocFileCache').")
  }
  if (!dir.exists(cache.dir)) {
    dir.create(cache.dir, recursive = TRUE, showWarnings = FALSE)
  }
  BiocFileCache::BiocFileCache(cache.dir, ask = FALSE)
}

#' Remote URLs for the bundled refGene GTF files
#'
#' @return A named list mapping genome build to its download URL.
#' @keywords internal
#' @noRd
refGeneURLs <- function() {
  list(
    hg19 = "https://github.com/OpenOmics/CellSight/releases/download/datav1.0.0/hg19.refGene.gtf.gz",
    hg38 = "https://github.com/OpenOmics/CellSight/releases/download/datav1.0.0/hg38.refGene.gtf.gz",
    mm9  = "https://github.com/user-attachments/files/32125619/mm9.refGene.gtf.gz",
    mm10 = "https://github.com/user-attachments/files/32125621/mm10.refGene.gtf.gz"
  )
}
