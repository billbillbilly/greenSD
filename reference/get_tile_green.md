# Classify greenspace based on map tile images

Generate high-resolution greenspace segmentation using WorldImagery map
tiles provided by esri and Sentinel-2 cloudless mosaic tiles provided by
EOX.

## Usage

``` r
get_tile_green(
  bbox = NULL,
  place = NULL,
  zoom = 17,
  provider = "esri",
  year = NULL,
  bright_filter = 0.85,
  gr_ratio_filter = 0.05,
  gb_ratio_filter = 0.05,
  clean = TRUE,
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

- zoom:

  numeric. Zoom level of map tile. The default is `17`.

- provider:

  character. One of "esri" and "eox".

- year:

  integer. The desired year for Sentinel-2 cloudless mosaic tiles. (This
  is required when `provider = "eox"`)

- bright_filter:

  numeric. To remove very bright pixels (concrete, roofs, glare) Default
  is 0.85. With lower `bright_filter`, more bright pixels will be
  excluded.

- gr_ratio_filter:

  numeric. (range from 0 to 1) To exclude pixels where green is only
  microscopically bigger than red. Default is 0.05. With higher
  `gr_ratio_filter`, more pixels will be excluded.

- gb_ratio_filter:

  numeric. (range from 0 to 1) To exclude pixels where green is only
  microscopically bigger than blue. Default is 0.05. With higher
  `gb_ratio_filter`, more pixels will be excluded.

- clean:

  logical. Whether to remove the blight and less green pixels based on
  `bright_filter`, `gr_ratio_filter`, and `gb_ratio_filter`.

- quiet:

  logical. Whether show progress bars for some process.

## Value

A list of two rasters including: greenspace segmentation (where 1 is
green and 0 is non-green) and original map tiles

## Note

The data derived from Esri WorldImagery may need to include appropriate
Esri copyright notice.

## Examples

``` r
g <- get_tile_green(
 # bbox = c(-83.087174,42.333373,-83.042542,42.358748),
 zoom = 15
)
```
