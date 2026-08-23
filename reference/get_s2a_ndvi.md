# Retrieve Sentinel-2-l2a images to compute NDVI

download Sentinel-2-l2a imagery data and compute NDVI. Users can define
an area of interest using a bounding box or place name.

## Usage

``` r
get_s2a_ndvi(
  bbox = NULL,
  place = NULL,
  datetime = c(),
  cloud_cover = 10,
  vege_perc = 0,
  select = "latest",
  method = "first",
  mask = TRUE,
  output_bands = NULL,
  quiet = TRUE
)
```

## Arguments

- bbox:

  `sf`, `sfc`, or a numeric vector (xmin, ymin, xmax, ymax) defining the
  area of interest. Optional if `place` is provided.

- place:

  character or vector. (optional) A single line address, e.g. ("1600
  Pennsylvania Ave NW, Washington") or a vector of addresses
  (c("Madrid", "Barcelona")).

- datetime:

  numeric vector of 2. The time of interest such as
  `c("2020-08-01", "2020-09-01")`.

- cloud_cover:

  numeric. Threshold for the percentage of cloud coverage. Desfault is
  10.

- vege_perc:

  numeric. Threshold for the percentage of vegetation coverage. Desfault
  is 0.

- select:

  character. one of "latest", "earliest", "all". The default is
  "latest".

- method:

  character. A method for mosaicing layers: one of "mean", "median",
  "min", "max", "modal", "sum", "first", "last". The default is "first".

- mask:

  logical (optional). Default is `TRUE`. If `TRUE`, masks the raster
  data using the given `bbox` or `place`.

- output_bands:

  vector. A list of band names (`c('B04', 'B08')`). The default is
  `NULL`. If `output_bands` is specified, NDVI will not be computed and
  only the specified bands will be returned. All available bands can be
  found
  [here](https://docs.sentinel-hub.com/api/latest/data/sentinel-2-l2a/#available-bands-and-data)

- quiet:

  logical. Whether show progress bars for some process.

## Value

A `SpatRaster` object containing (multiple) NDVI layer(s) (for different
period of time) `select = "latest"` or `select = "first"` (or if
`mask = TRUE` and `select = "all"`)

A `List` of NDVI rasters if `mask = FALSE` and `select = "all"`.

## Examples

``` r
# \donttest{
result <- get_s2a_ndvi(
  place = 'New York',
  datetime = c("2020-08-01", "2020-09-01")
)
#> ℹ Start downloading data ...
#> ℹ Importing bands ...
#> ℹ Mosaicing, masking and cropping ...
#> ✔ Data successfully processed.
#> ✔ Completed. Time taken: 1 minutes.
# }
```
