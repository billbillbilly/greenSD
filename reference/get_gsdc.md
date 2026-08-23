# Download Greenspace Seasonality Data Cube

download Greenspace Seasonality Data Cube for an urban area. Retrieves
high-resolution greenspace seasonality data from the Sentinel-2-based
global dataset developed by Wu et al. (2024). Users can define a city of
interest using a bounding box, place name, coordinates, or unique city
ID (UID).

## Usage

``` r
get_gsdc(
  bbox = NULL,
  place = NULL,
  location = NULL,
  UID = NULL,
  year = NULL,
  time = NULL,
  mask = TRUE,
  quiet = TRUE
)
```

## Arguments

- bbox:

  `sf`, `sfc`, or a numeric vector (xmin, ymin, xmax, ymax) defining the
  area of interest. Optional if `place`, `location`, or `UID` is
  provided.

- place:

  character or vector. (optional) A single line address, e.g. ("1600
  Pennsylvania Ave NW, Washington") or a vector of addresses
  (c("Madrid", "Barcelona")). This can be ignored if `location` is
  specified.

- location:

  vector or sf point. A point of interest. Ignored if `UID` is
  specified.

- UID:

  numeric. Urban area ID. To check the ID of an available urban area,
  use
  [`check_available_urban()`](https://billbillbilly.github.io/greenSD/reference/check_available_urban.md)

- year:

  numeric. (required) The year of interest.

- time:

  Character vector of length 2 or character. (optional) Start and end
  dates in `"MM-DD"` format (e.g., `c("03-20", "10-15")` or `"07-10"`).
  Used to subset the 10-day interval data cube by time.

- mask:

  logical (optional). Default is `TRUE`. If `TRUE`, masks the raster
  data using the given `bbox` or `place` if it is specified.

- quiet:

  logical. Whether show progress bars for some process.

## Value

A `SpatRaster` object containing the greenspace seasonality data.

## Details

The Greenspace Data Cube is organized into 36 bands per year, each
representing a 10-day interval.

## Note

Use
[`check_available_urban()`](https://billbillbilly.github.io/greenSD/reference/check_available_urban.md)
and
[`check_urban_boundary()`](https://billbillbilly.github.io/greenSD/reference/check_urban_boundary.md)
to see supported cities and their boundaries.

## References

Wu, S., Song, Y., An, J. et al. High-resolution greenspace dynamic data
cube from Sentinel-2 satellites over 1028 global major cities. Sci Data
11, 909 (2024). https://doi.org/10.1038/s41597-024-03746-7

## Examples

``` r
result <- get_gsdc(UID = 0,
                   # year = 2022
                  )
#> ℹ `year` is missing.
```
