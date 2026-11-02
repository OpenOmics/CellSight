test_that("getRefGeneGTF rejects unsupported genomes before touching the network", {
  expect_error(
    getRefGeneGTF("hg18", cache = NULL, verbose = FALSE),
    "No refGene GTF is available for genome 'hg18'"
  )
})

test_that("refGeneCache creates its cache directory", {
  testthat::skip_if_not_installed("BiocFileCache")
  dir <- file.path(tempdir(), "cellsight-cache-test")
  on.exit(unlink(dir, recursive = TRUE))
  expect_false(dir.exists(dir))

  cache <- refGeneCache(cache.dir = dir)
  expect_true(dir.exists(dir))
  expect_s4_class(cache, "BiocFileCache")
})
