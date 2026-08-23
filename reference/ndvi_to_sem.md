# ndvi_to_sem

Convert ndvi raster data into semantic vegetation areas

## Usage

``` r
ndvi_to_sem(r = NULL, threshold = c(0.2, 0.5), quiet = FALSE)
```

## Arguments

- r:

  A SpatRaster with single greenspace layer, typically the output from
  [`get_esa_wc()`](https://billbillbilly.github.io/greenSD/reference/get_esa_wc.md),
  or
  [`get_s2a_ndvi()`](https://billbillbilly.github.io/greenSD/reference/get_s2a_ndvi.md).

- threshold:

  numeric vector of two. Thresholds, defaulting to `c(0.2, 0.5)`, for
  classify two types of vegetation areas according to Hashim et al.
  (2019): (1) Non-vegetation (Development and bare land): NDVI values
  generally below `0.2`. (2) Low vegetation (Shrub and grassland): NDVI
  values generally between `0.2` and `0.5`. (2) High vegetation
  (Temperate and Tropical urban forest ): NDVI values generally between
  `0.5` and `1.0`.

- quiet:

  logical. Whether show progress bars for some process.

## Value

SpatRaster. A raster, where `0` represents non-green area, `1`
represents shrub and grassland, and `2` represents trees.

## References

Hashim, H., Abd Latif, Z., & Adnan, N. A. (2019). Urban vegetation
classification with NDVI threshold value method with very high
resolution (VHR) Pleiades imagery. The International Archives of the
Photogrammetry, Remote Sensing and Spatial Information Sciences, 42,
237-240.

## Examples

``` r
sample_data <- terra::rast(system.file("extdata", "detroit_gs.tif", package = "greenSD"))
seg <- ndvi_to_sem(sample_data$`25_NDVI`, threshold = c(0.2, 0.6))
```
