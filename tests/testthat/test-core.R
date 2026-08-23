testthat::test_that("runs correctly", {
  city <- greenSD::get_gsdc()
  esa <- greenSD::get_esa_wc()
  s2a <- greenSD::get_s2a_ndvi()
  sample <- greenSD::sample_values()
  t <- greenSD::get_tile_green()
  testthat::expect_type(city, "NULL")
  testthat::expect_type(esa, "NULL")
  testthat::expect_type(s2a, "NULL")
  testthat::expect_type(sample, "NULL")
  testthat::expect_type(t, "NULL")
})

testthat::test_that("get_gsdc location resolves matched UID before downloading", {
  testthat::local_mocked_bindings(
    check_overlap = function(geometry) 1825,
    get_data_with_uid = function(id, y) {
      testthat::expect_identical(id, 1825)
      testthat::expect_identical(y, 2022)
      "mock-url"
    },
    download_data = function(urls) {
      testthat::expect_identical(urls, "mock-url")
      "downloaded"
    },
    report_time = function(start_time) NULL,
    .package = "greenSD"
  )

  out <- greenSD::get_gsdc(location = c(-83.10215, 42.38342), year = 2022)
  testthat::expect_identical(out, "downloaded")
})

testthat::test_that("get_s2a_ndvi returns NULL for empty Sentinel search results", {
  testthat::local_mocked_bindings(
    download_sentinel = function(...) list(),
    .package = "greenSD"
  )

  out <- greenSD::get_s2a_ndvi(
    bbox = c(-83.087174, 42.333373, -83.042542, 42.358748),
    datetime = c("1900-01-01", "1900-01-02")
  )
  testthat::expect_null(out)
})

testthat::test_that("get_esa_wc validates datatype before remote work", {
  testthat::expect_error(
    greenSD::get_esa_wc(
      bbox = c(-83.087174, 42.333373, -83.042542, 42.358748),
      datatype = "bad"
    ),
    "`datatype` must be one of"
  )
})

testthat::test_that("sample_values accepts documented year alias", {
  r <- terra::rast(
    nrows = 2, ncols = 2,
    xmin = -84, xmax = -83,
    ymin = 42, ymax = 43,
    crs = "EPSG:4326",
    vals = 1:4
  )
  names(r) <- "value"

  testthat::local_mocked_bindings(
    get_gsdc = function(bbox, year, mask) {
      testthat::expect_identical(year, 2022)
      r
    },
    .package = "greenSD"
  )

  out <- greenSD::sample_values(
    samples = matrix(c(-83.75, 42.75), ncol = 2),
    year = 2022
  )
  testthat::expect_named(out, "value")
})
