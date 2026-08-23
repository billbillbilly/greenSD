# exposure

Computes population-weighted greenspace fraction or human exposure to
greenspace based on a population-weighted exposure model (Chen et al.,
2022), using population data from the Global Human Settlement Layer
(GHSL; Pesaresi et al., 2024). See **Details** for the underlying method
and assumptions.

## Usage

``` r
compute_exposure(
  r = NULL,
  res = c(10, 10),
  pop_year = 2020,
  radius = 500,
  grid_size = NULL,
  height = FALSE,
  pop_out = FALSE,
  quiet = TRUE
)
```

## Arguments

- r:

  A SpatRaster with single/multiple greenspace layer(s), either
  fractional or binary (where non-green = 0 and green = 1), typically
  the output from
  [`get_gsdc()`](https://billbillbilly.github.io/greenSD/reference/get_gsdc.md),
  [`get_esa_wc()`](https://billbillbilly.github.io/greenSD/reference/get_esa_wc.md),
  or
  [`get_tile_green()`](https://billbillbilly.github.io/greenSD/reference/get_tile_green.md).

- res:

  numeric vector of length 2. The actual spatial resolution (in meters).
  Default is `c(10, 10)`.

- pop_year:

  numeric. Year of the GHSL dataset to use. Must be one of: 2015, 2020,
  2025, or 2030. Default is 2020.

- radius:

  numeric. Buffer radius (in meters) used for local averaging. Default
  is `500`.

- grid_size:

  numeric. Optional. If provided, output is aggregated to grid cells of
  this size (in meters) and returned as an `sf` object.

- height:

  logical. Whether to compute greenspace volume for population-weighted
  greenspace fraction or human exposure to greenspace using Meta's
  global canopy height map (Tolan et al., 2024). (The default is FALSE)

- pop_out:

  logical. Whether return population layer.

- quiet:

  logical. Whether show progress bars for some process.

## Value

SpatRaster or sf. A `SpatRaster` (if `grid_size` is `NULL`) with layers
`pwgf_*`, or an `sf` object with columns `pwge_*` representing
population-weighted greenspace exposure values aggregated to each grid
polygon.

## Details

This function implements the population-weighted greenspace exposure
(PWGE) model:

1.  Start with a population raster. Each pixel \\ i \\ has a population
    value \\ P_i \\.

2.  Create a circular buffer of radius \\ d \\ around each pixel center.

3.  For each buffer, calculate greenspace fraction: \$\$G_i^d =
    \frac{\text{Area of greenspace within buffer}}{\text{Total buffer
    area}}\$\$

4.  Repeat for all \\ i = 1, 2, ..., N \\ grid cells.

5.  Compute overall exposure: \$\$GE^d = \frac{\sum_i P_i \cdot
    G_i^d}{\sum_i P_i}\$\$

## References

Chen, B., Wu, S., Song, Y. et al. Contrasting inequality in human
exposure to greenspace between cities of Global North and Global South.
Nat Commun 13, 4636 (2022). https://doi.org/10.1038/s41467-022-32258-4

Pesaresi, M., Schiavina, M., Politis, P., Freire, S., Krasnodębska, K.,
Uhl, J. H., … Kemper, T. (2024). Advances on the Global Human Settlement
Layer by joint assessment of Earth Observation and population survey
data. International Journal of Digital Earth, 17(1).
https://doi.org/10.1080/17538947.2024.2390454

Tolan, J., Yang, H. I., Nosarzewski, B., Couairon, G., Vo, H. V.,
Brandt, J., ... & Couprie, C. (2024). Very high resolution canopy height
maps from RGB imagery using self-supervised vision transformer and
convolutional decoder trained on aerial lidar. Remote Sensing of
Environment, 300, 113888.

## Examples

``` r
sample_data <- terra::rast(system.file("extdata", "detroit_gs.tif", package = "greenSD"))
pwgf <- compute_exposure(
  # r = sample_data,
  pop_year = 2020,
  radius = 1500
)
```
