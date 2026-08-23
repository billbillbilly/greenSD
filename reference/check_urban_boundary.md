# Get an urban area boundary based on the UID

This function returns a polygon of a city boundary based on the UID

## Usage

``` r
check_urban_boundary(uid = NULL, plot = TRUE, test = FALSE)
```

## Arguments

- uid:

  numeric. Urban area ID. To check the ID of an available urban area,
  use
  [`check_available_urban()`](https://billbillbilly.github.io/greenSD/reference/check_available_urban.md)

- plot:

  logical. Whether to plot city boundary

- test:

  logical. (ignored) Only for testing.

## Value

sf

## References

Wu, S., Song, Y., An, J. et al. High-resolution greenspace dynamic data
cube from Sentinel-2 satellites over 1028 global major cities. Sci Data
11, 909 (2024). https://doi.org/10.1038/s41597-024-03746-7

## Examples

``` r
check_urban_boundary(test = TRUE)
#> NULL
```
