# Get all of the urban areas in the Greenspace Seasonality Data Cube

This function returns all of the urban areas in the Greenspace
Seasonality Data Cube dataset.

## Usage

``` r
check_available_urban(test = FALSE)
```

## Arguments

- test:

  logical. (ignored) Only for testing.

## Value

dataframe

## Note

You can explore all available urban areas in an interacive map at:
<https://github.com/billbillbilly/greenSD/blob/main/scripts/city_urban_boundaries.geojson>

## References

Wu, S., Song, Y., An, J. et al. High-resolution greenspace dynamic data
cube from Sentinel-2 satellites over 1028 global major cities. Sci Data
11, 909 (2024). https://doi.org/10.1038/s41597-024-03746-7

## Examples

``` r
check_available_urban(test = TRUE)
#> NULL
```
