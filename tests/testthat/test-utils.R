testthat::test_that("runs correctly", {
  cities <- greenSD::check_available_urban(test = TRUE)
  boundary <- greenSD::check_urban_boundary(test = TRUE)
  band_index <- greenSD::get_band_index_by_time(c("03-20", "10-15"), year = 2020)
  sample_data <- terra::rast(system.file("extdata", "detroit_gs.tif", package = "greenSD"))
  gif <- greenSD::to_gif(sample_data)
  testthat::expect_type(cities, "NULL")
  testthat::expect_type(boundary, "NULL")
  testthat::expect_type(band_index, "integer")
  testthat::expect_type(gif, "externalptr")
})

testthat::test_that("EOX WMS XML uses independent x and y dimensions", {
  xml <- greenSD:::write_eox_wms_xml(
    bbox = c(-83.0, 42.0, -82.0, 42.5),
    year = 2024,
    zoom = 10
  )
  sizex <- sub(".*<SizeX>([0-9]+)</SizeX>.*", "\\1", grep("SizeX", xml, value = TRUE))
  sizey <- sub(".*<SizeY>([0-9]+)</SizeY>.*", "\\1", grep("SizeY", xml, value = TRUE))
  testthat::expect_false(identical(sizex, sizey))
})
