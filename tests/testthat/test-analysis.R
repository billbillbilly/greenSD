testthat::test_that("runs correctly", {
  pwgf <- greenSD::compute_exposure()
  ndvi_seg <- greenSD::ndvi_to_sem()
  morpho <- greenSD::compute_morphology()
  testthat::expect_type(pwgf, "NULL")
  testthat::expect_type(ndvi_seg, "NULL")
  testthat::expect_type(morpho, "NULL")
})

testthat::test_that("compute_exposure returns local fraction, not population-weighted numerator", {
  r <- terra::rast(
    nrows = 20, ncols = 20,
    xmin = -83.25, xmax = -83.23,
    ymin = 42.35, ymax = 42.37,
    crs = "EPSG:4326",
    vals = 1
  )
  pop <- terra::rast(
    nrows = 20, ncols = 20,
    xmin = -83.25, xmax = -83.23,
    ymin = 42.35, ymax = 42.37,
    crs = "EPSG:4326",
    vals = 10
  )

  testthat::local_mocked_bindings(
    download_GHSL = function(bbox, year) pop,
    report_time = function(start_time) NULL,
    .package = "greenSD"
  )

  out <- greenSD::compute_exposure(r, radius = 500, quiet = TRUE)
  testthat::expect_true(max(terra::values(out), na.rm = TRUE) <= 1)
  testthat::expect_named(out, "pwgf_1")
})
