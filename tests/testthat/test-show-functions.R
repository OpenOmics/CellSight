test_that("showOrder summarises the config as a data.frame", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))

  grDevices::pdf(nullfile())
  on.exit(grDevices::dev.off())
  out <- showOrder(scConf)

  expect_s3_class(out, "data.table")
  expect_setequal(out$`actual name`, c("group", "donor"))
  expect_true(all(out$type == "cat."))
  expect_equal(out[`actual name` == "group"]$nlevels, 2)
  expect_equal(out[`actual name` == "donor"]$nlevels, 3)
})

test_that("showLegend returns one legend per categorical metadata plus continuous", {
  seu <- test_seurat()
  scConf <- createConfig(seu, meta.to.include = c("group", "donor"))

  grDevices::pdf(nullfile())
  on.exit(grDevices::dev.off())
  legends <- showLegend(scConf)

  expect_type(legends, "list")
  expect_true(all(c("group", "donor", "continuous") %in% names(legends)))
})
