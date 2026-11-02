test_that("createConfig builds a usable config from a Seurat object", {
  seu <- test_seurat()
  scConf <- createConfig(seu)

  expect_s3_class(scConf, "data.table")
  expect_true(all(c("group", "donor") %in% scConf$ID))
  expect_true(nrow(scConf[grp == TRUE]) >= 1)
})

test_that("meta.to.include restricts which columns are kept", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))
  expect_equal(sort(scConf$ID), c("donor", "group"))
})

test_that("createConfig errors on unknown meta.to.include columns", {
  seu <- test_seurat()
  expect_error(
    createConfig(seu, meta.to.include = c("group", "not_a_column")),
    "Some metadata are missing"
  )
})

test_that("createConfig requires at least two metadata columns", {
  seu <- test_seurat()
  expect_error(
    createConfig(seu, meta.to.include = "group"),
    "At least 2 metadata"
  )
})

test_that("createConfig drops metadata above maxLevels, with a warning", {
  seu <- test_seurat()
  expect_warning(
    scConf <- createConfig(seu,
      meta.to.include = c("group", "donor", "nCount_RNA"),
      maxLevels = 2
    ),
    "donor.*excluded"
  )
  expect_false("donor" %in% scConf$ID)
  expect_true("group" %in% scConf$ID)
})

test_that("createConfig errors when no multi-level metadata is present", {
  seu <- test_seurat()
  expect_error(
    createConfig(seu, meta.to.include = c("nCount_RNA", "nFeature_RNA")),
    "did not detect any multi-group"
  )
})

test_that("createConfig errors when the object has no dimension reduction", {
  testthat::skip_if_not_installed("Seurat")
  counts <- Matrix::Matrix(matrix(1:12, nrow = 3), sparse = TRUE)
  rownames(counts) <- paste0("g", 1:3)
  colnames(counts) <- paste0("c", 1:4)
  obj <- Seurat::CreateSeuratObject(
    counts = counts, min.cells = 0,
    min.features = 0
  )
  obj$grp <- factor(c("A", "A", "B", "B"))

  expect_error(createConfig(obj), "did not detect any dimension reduction")
})

test_that("createConfig rejects unsupported object types", {
  expect_error(createConfig(42), "Only Seurat/ArchR objects")
})
