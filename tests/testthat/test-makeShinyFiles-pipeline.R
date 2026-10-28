test_that("makeShinyFiles writes every data file for a single dataset", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))
  dir <- tempfile("shinyApp")

  makeShinyFiles(seu, scConf,
    assay = "RNA", shiny.prefix = "sc1",
    shiny.dir = dir
  )

  expected <- paste0(dir, "/sc1", c(
    "conf.qs2.rds", "meta.qs2.rds",
    "gene.qs2.rds", "dimr.qs2.rds",
    "def.qs2.rds", "assay_RNA.h5"
  ))
  expect_true(all(file.exists(expected)))

  sc1def <- qs2::qs_read(paste0(dir, "/sc1def.qs2.rds"))
  expect_true(sc1def$gene1[["RNA"]] %in% rownames(seu))
})

test_that("makeShinyCodes works for a single dataset without shiny.headers", {
  # Regression test: shiny.headers used to have no default, so this call
  # errored with "argument \"shiny.headers\" is missing, with no default"
  # even though shiny.headers is documented as ignored for one dataset.
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))
  dir <- tempfile("shinyApp")
  makeShinyFiles(seu, scConf,
    assay = "RNA", shiny.prefix = "sc1",
    shiny.dir = dir
  )

  expect_no_error(
    makeShinyCodes(
      shiny.title = "Test app", shiny.prefix = "sc1",
      shiny.dir = dir
    )
  )
  expect_true(all(file.exists(paste0(dir, "/", c(
    "ui.R", "server.R",
    "shinyFunc.R"
  )))))
})

test_that("makeShinyCodes requires shiny.headers to match multiple prefixes", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))
  dir <- tempfile("shinyApp")
  makeShinyFiles(seu, scConf,
    assay = "RNA", shiny.prefix = "sc1",
    shiny.dir = dir
  )
  makeShinyFiles(seu, scConf,
    assay = "RNA", shiny.prefix = "sc2",
    shiny.dir = dir
  )

  expect_error(
    makeShinyCodes(
      shiny.title = "Test app", shiny.prefix = c("sc1", "sc2"),
      shiny.headers = "only one", shiny.dir = dir
    ),
    "length of shiny.prefix and shiny.headers does not match"
  )

  expect_no_error(
    makeShinyCodes(
      shiny.title = "Test app", shiny.prefix = c("sc1", "sc2"),
      shiny.headers = c("One", "Two"), shiny.dir = dir
    )
  )
})

test_that("makeShinyCodes errors clearly when the data files are missing", {
  dir <- tempfile("shinyApp")
  dir.create(dir)
  expect_error(
    makeShinyCodes(
      shiny.title = "Test app", shiny.prefix = "sc1",
      shiny.dir = dir
    ),
    "files missing for sc1 dataset"
  )
})

test_that("makeShinyFiles errors on a precomputed DEG path that does not exist", {
  # Regression test: the missing-file branch called an undefined err()
  # function, so this used to fail with "could not find function \"err\""
  # instead of a clear, catchable error naming the bad path.
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))
  dir <- tempfile("shinyApp")

  expect_error(
    makeShinyFiles(seu, scConf,
      assay = "RNA", shiny.prefix = "sc1",
      shiny.dir = dir,
      precomputed.deg = "does_not_exist.csv",
      clusters = c("0", "1")
    ),
    "Precomputed DEG file not found"
  )
})

test_that("makeShinyFiles rejects unsupported object types", {
  # Regression test: the dispatcher had no final else/stop, so an
  # unsupported object silently did nothing and returned NULL.
  expect_error(
    makeShinyFiles("not-a-seurat-object.rds", data.table::data.table()),
    "Only Seurat/ArchR objects"
  )
})
