#' Generate data files required for shiny app (scRNA type data)
#'
#' Generate data files required for shiny app, specifically scRNA-seq data
#' Six files will be generated, namely
#' (i) the shinycell config \code{prefix_conf.rds},
#' (ii) the single-cell metadata \code{prefix_meta.rds},
#' (iii) the single-cell assays \code{prefix_assay_X.h5},
#' (iv) the feature mapping object config \code{prefix_gene.rds},
#' (v) the dimension reduction embeddings \code{prefix_dimr.rds} and
#' (vi) the defaults for the Shiny app \code{prefix_def.rds}.
#' A prefix is specified for each set of files to allow for multiple
#' single-cell datasets in a single Shiny app.
#'
#' @param obj input Seurat (v3+) object or input file path for h5ad file
#' @param scConf shinycell config data.table
#' @param gex.assay assay(s) in single-cell data object to use. Multiple assays
#'   can now be incorporated and all assays are used by default (with the first
#'   assay being the default assay), which must match one of the following:
#'   \itemize{
#'     \item{Seurat objects}: "RNA" or "integrated" assay,
#'       default is "RNA"
#'     \item{h5ad files}: "X" or any assay in "layers",
#'       default is "X"
#'   }
#' @param gex.slot slot in single-cell assay to plot. This is only used
#'   for Seurat objects (v3+). Default is to use the "data" slot
#' @param dimred.to.use specify the dimension reduction to use. Default is to
#'   use all except PCA
#' @param shiny.prefix specify file prefix
#' @param shiny.dir specify directory to create the shiny app in
#' @param default.gene1 specify primary default gene to show, which be present
#'   in the default assay for Seurat or X layer in scanpy h5ad
#' @param default.gene2 specify secondary default gene to show, which be present
#'   in the default assay for Seurat or X layer in scanpy h5ad
#' @param default.multigene character vector specifying default genes to
#'   show in bubbleplot / heatmap, which be present
#'   in the default assay for Seurat or X layer in scanpy h5ad
#' @param default.dimred character vector specifying the two default dimension
#'   reductions. Default is to use UMAP if not TSNE embeddings
#' @param chunkSize number of genes written to h5file at any one time. Lower
#'   this number to reduce memory consumption. Should not be less than 10
#'
#' @return data files required for shiny app
#'
#' @author John F. Ouyang
#'
#' @import data.table hdf5r reticulate hdf5r
#'
#' @examples
#' makeShinyFilesGEX(seu, scConf,
#'   shiny.prefix = "sc1", shiny.dir = "shinyApp/",
#'   default.gene1 = "POU5F1", default.gene2 = "APOA1",
#'   default.multigene = c("POU5F1", "APOA1", "GPRC5A", "TBXT", "ISL1"),
#'   default.dimred = "umap"
#' )
#'
#' @export
makeShinyFilesDEG <- function(
    obj,
    scConf,
    shiny.dir,
    shiny.prefix,
    precomputed.deg,
    clusters,
    chunkSize = 500) {
  if (!clusters %in% names(obj@meta.data)) {
    stop(paste0('"', clusters, '" not found in Seurat object meta data!'))
  }
  defs_file <- paste0(shiny.dir, "/", shiny.prefix, "def.rds")
  if (!file.exists(defs_file)) {
    stop(paste0(shiny.dir, "/", shiny.prefix, "def.rds does not exist! Cannot create DEG data"))
  }
  # update defitions to include config values for DEG page
  defs <- readRDS(defs_file)
  defs$DEG <- clusters
  saveRDS(defs, defs_file)

  # read in clustermap
  cell_id <- "orig.ident"
  clustermap <- subset(obj@meta.data, select = c(cell_id, clusters))

  # cluste h5 map creation
  n_rows <- nrow(clustermap)
  n_cols <- ncol(clustermap)
  total_size <- object.size(clustermap)
  bytes_per_row <- as.numeric(total_size) / n_rows
  chunks <- ceiling(1024 / bytes_per_row)
  write_df_chunked_hdf5r(
    clustermap,
    file = paste0(shiny.dir, "/", shiny.prefix, "deg.h5"),
    key = "cell2cluster",
    chunk_rows = chunks,
    compression_level = 0,
    quiet = TRUE
  )

  # read in markergenes
  markergenes <- tryCatch(
    {
      # Try tab-separated first
      read.table(precomputed.deg,
        header = TRUE, sep = "\t",
        stringsAsFactors = FALSE, quote = "\""
      )
    },
    error = function(e) {
      # Fall back to whitespace-separated
      read.table(precomputed.deg,
        header = TRUE, sep = "",
        stringsAsFactors = FALSE, quote = "\""
      )
    }
  )

  # Verify we got the expected columns
  expected_cols <- c("p_val", "avg_log2FC", "pct.1", "pct.2", "p_val_adj", "cluster", "gene")
  if (ncol(markergenes) == 1 || !all(expected_cols %in% colnames(markergenes))) {
    stop(
      "Failed to parse marker genes file correctly. Expected columns: ",
      paste(expected_cols, collapse = ", ")
    )
  }

  # Validate DEG cluster levels match metadata cluster levels
  deg_clusters <- sort(unique(as.character(markergenes$cluster)))
  meta_clusters <- sort(unique(as.character(obj@meta.data[[clusters]])))
  if (!all(deg_clusters %in% meta_clusters)) {
    missing <- setdiff(deg_clusters, meta_clusters)
    stop(
      "DEG markers contain cluster(s) not found in metadata column '", clusters, "': ",
      paste(missing, collapse = ", "),
      "\n  DEG clusters: ", paste(deg_clusters, collapse = ", "),
      "\n  Metadata clusters: ", paste(meta_clusters, collapse = ", ")
    )
  }

  # Validate that the clusters column exists in scConf (i.e. it was not filtered out)
  if (!clusters %in% scConf$ID && !clusters %in% scConf$UI) {
    stop(
      "Cluster label '", clusters, "' was not included in the ShinyCell config (sc1conf). ",
      "It may have been removed by metadata filtering (rmmeta/unsupported assay pattern). ",
      "Please ensure this column is retained in the config."
    )
  }

  # markergene h5 creation
  n_rows <- nrow(markergenes)
  n_cols <- ncol(markergenes)
  total_size <- object.size(markergenes)
  bytes_per_row <- as.numeric(total_size) / n_rows
  chunks <- ceiling(1024 / bytes_per_row)
  write_df_chunked_hdf5r(
    markergenes,
    file = paste0(shiny.dir, "/", shiny.prefix, "deg.h5"),
    key = "markergenes",
    chunk_rows = chunks,
    compression_level = 0,
    quiet = TRUE
  )
}
