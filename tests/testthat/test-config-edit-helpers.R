test_that("delMeta removes metadata and errors on an unknown name", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))

  scConf2 <- delMeta(scConf, "donor")
  expect_false("donor" %in% scConf2$ID)
  expect_true("group" %in% scConf2$ID)

  expect_error(delMeta(scConf, "nope"), "not found")
})

test_that("addMeta brings back a dropped column and enforces maxLevels", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))
  scConf <- delMeta(scConf, "donor")

  scConf2 <- addMeta(scConf, "donor", seu)
  expect_true("donor" %in% scConf2$ID)

  expect_error(
    addMeta(scConf, "donor", seu, maxLevels = 1),
    "exceeded the maximum"
  )
  expect_error(
    addMeta(scConf, "not_a_column", seu),
    "not found in single-cell data object"
  )
})

test_that("modMetaName renames display labels without touching ID", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))

  scConf <- modMetaName(scConf, "group", "Group label")
  expect_equal(scConf[ID == "group"]$UI, "Group label")
  expect_true("group" %in% scConf$ID)

  expect_error(
    modMetaName(scConf, c("group", "donor"), "only one"),
    "do not match"
  )
  expect_error(modMetaName(scConf, "not_a_column", "x"), "not found")
})

test_that("modLabels relabels factor levels in display order", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))

  scConf <- modLabels(scConf, "group", c("Alpha", "Beta"))
  expect_equal(
    strsplit(scConf[ID == "group"]$fUI, "\\|")[[1]],
    c("Alpha", "Beta")
  )

  expect_error(modLabels(scConf, "group", "Only one"), "does not match")
  expect_error(
    modLabels(scConf, c("group", "donor"), c("a", "b")),
    "only one metadata"
  )
  expect_error(modLabels(scConf, "not_a_column", "x"), "not found")
})

test_that("modColours validates colours and vector length", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))

  scConf <- modColours(scConf, "group", c("red", "blue"))
  expect_equal(
    strsplit(scConf[ID == "group"]$fCL, "\\|")[[1]],
    c("red", "blue")
  )

  expect_error(
    modColours(scConf, "group", c("not-a-colour", "blue")),
    "invalid colours"
  )
  expect_error(modColours(scConf, "group", "red"), "does not match")
})

test_that("reorderMeta requires a complete permutation of IDs", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))

  scConf2 <- reorderMeta(scConf, c("donor", "group"))
  expect_equal(as.character(scConf2$ID), c("donor", "group"))

  expect_error(reorderMeta(scConf, "group"), "does not match")
  expect_error(
    reorderMeta(scConf, c("group", "donor", "extra")),
    "does not match"
  )
})

test_that("modDefault sets default1/default2 and validates names", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))

  scConf <- modDefault(scConf, "donor", "group")
  expect_equal(scConf[ID == "donor"]$default, 1)
  expect_equal(scConf[ID == "group"]$default, 2)

  expect_error(
    modDefault(scConf, c("group", "donor"), "donor"),
    "only one default1"
  )
  expect_error(
    modDefault(scConf, "donor", c("group", "donor")),
    "only one default2"
  )
  expect_error(modDefault(scConf, "nope", "donor"), "default1 not found")
  expect_error(modDefault(scConf, "donor", "nope"), "default2 not found")
})
