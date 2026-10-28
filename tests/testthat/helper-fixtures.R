# Fixtures shared across test files. Kept deliberately tiny (tens of cells
# and genes) so the suite stays fast and does not depend on any external
# data download, per the Bioconductor testing guidelines
# (https://contributions.bioconductor.org/tests.html).

#' Build a small, self-contained Seurat object for exercising the
#' createConfig() / makeShinyFiles() / makeShinyCodes() pipeline.
make_test_seurat <- function(n_cells = 40, n_genes = 30, seed = 1) {
  testthat::skip_if_not_installed("Seurat")
  testthat::skip_if_not_installed("SeuratObject")

  set.seed(seed)
  counts <- matrix(
    stats::rpois(n_cells * n_genes, lambda = 5),
    nrow = n_genes, ncol = n_cells,
    dimnames = list(
      paste0("Gene", seq_len(n_genes)),
      paste0("Cell", seq_len(n_cells))
    )
  )
  counts <- Matrix::Matrix(counts, sparse = TRUE)

  obj <- Seurat::CreateSeuratObject(
    counts = counts, assay = "RNA",
    min.cells = 0, min.features = 0
  )
  obj$group <- factor(rep(c("A", "B"), length.out = n_cells))
  obj$donor <- factor(rep(c("D1", "D2", "D3"), length.out = n_cells))

  obj <- Seurat::NormalizeData(obj, verbose = FALSE)
  obj <- Seurat::FindVariableFeatures(obj,
    nfeatures = min(20, n_genes),
    verbose = FALSE
  )
  obj <- Seurat::ScaleData(obj, verbose = FALSE)
  obj <- Seurat::RunPCA(obj, npcs = 5, verbose = FALSE)
  # Suppresses Seurat's one-time, session-level informational message about
  # the UMAP backend change; unrelated to anything this suite checks.
  obj <- suppressWarnings(
    Seurat::RunUMAP(obj, dims = 1:5, n.neighbors = 10, verbose = FALSE)
  )
  obj
}

# Built once per test session and reused, since it is the same handful of
# RunPCA/RunUMAP calls in every test file that needs it.
.test_seurat_cache <- new.env(parent = emptyenv())

#' Cached accessor for the fixture above.
test_seurat <- function() {
  if (is.null(.test_seurat_cache$obj)) {
    .test_seurat_cache$obj <- make_test_seurat()
  }
  .test_seurat_cache$obj
}
