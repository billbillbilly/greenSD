# Convert A Multi-layer Raster to GIF

Export a multi-layer raster (`SpatRaster`) or vector layer (`sf`) with
multiple numeric value columns to an animated GIF.

## Usage

``` r
to_gif(
  r,
  fps = 5,
  width = 600,
  height = 600,
  axes = TRUE,
  title_prefix = NULL,
  border = FALSE
)
```

## Arguments

- r:

  SpatRaster or sf. A SpatRaster with multiple layers or an sf object
  with multiple numeric value columns.

- fps:

  numeric. Frames per second (default 5).

- width:

  numeric. Width of output GIF in pixels.

- height:

  numeric. Height of output GIF in pixels.

- axes:

  logical. Draw axes?

- title_prefix:

  character or character vector.

- border:

  character. Color of polygon border(s); using NA hides them. Only
  optional when `r` is an sf object.

## Value

An animated magick image object (GIF).

## Examples

``` r
sample_data <- terra::rast(system.file("extdata", "detroit_gs.tif", package = "greenSD"))
gif <- to_gif(sample_data)
```
