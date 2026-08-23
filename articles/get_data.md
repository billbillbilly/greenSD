# get_data

## Donwload multi-band data from Greenspace Seasonality Data Cube with specified area/point of inerest

Downloading data may take more than 5 minutes.

#### By bounding box

``` r

gs <- greenSD::get_gsdc(bbox = c(-83.272828,42.343950,-83.218926,42.379719), year = 2022, mask = TRUE)
```

#### By place name

``` r

gs <- greenSD::get_gsdc(place = 'Detroit', year = 2022)
```

#### By coordinates (point)

``` r

gs <- greenSD::get_gsdc(location = c(-83.10215, 42.38342), year = 2022)
```

#### By UID and time range

``` r

# check UID 
greenSD::check_available_urban()
gs <- greenSD::get_gsdc(UID = 1825, year = 2022, time = c("03-01", "09-01"))
```

## Download ESA WorldCover 10m Annual Dataset

#### Get NDVI data by place name

``` r

ndvi <- greenSD::get_esa_wc(place = 'Detroit', datatype = "ndvi")
```

#### Get land cover data from ESA WorldCover 10m dataset

``` r

lc <- greenSD::get_esa_wc(place = 'Detroit', datatype = "landcover")
```

## Download Sentinel-2 10m Land Use/Land Cover Time Series

The `datatype = "lulc"` option retrieves annual 9-class land use/land
cover maps from the [Impact Observatory Sentinel-2 10m LULC Time
Series](https://www.impactobservatory.com/maps-for-good/), hosted on a
public AWS S3 bucket (no authentication required). Annual maps are
available from 2017 to 2024, with a new year added each January.

The 9 land cover classes are: Water (1), Trees (2), Flooded Vegetation
(4), Crops (5), Built Area (7), Bare Ground (8), Snow/Ice (9), Clouds
(10), Rangeland (11).

#### Get LULC data by place name

``` r

lulc <- greenSD::get_esa_wc(place = 'Detroit', datatype = "lulc", year = 2023)
```

#### Get LULC data by bounding box

``` r

lulc <- greenSD::get_esa_wc(
  bbox = c(-83.272828, 42.343950, -83.218926, 42.379719),
  datatype = "lulc",
  year = 2024
)
```

#### Compare land cover change across years

``` r

lulc_2017 <- greenSD::get_esa_wc(place = 'Detroit', datatype = "lulc", year = 2017)
lulc_2023 <- greenSD::get_esa_wc(place = 'Detroit', datatype = "lulc", year = 2023)

# Stack and compare
lulc_change <- c(lulc_2017, lulc_2023)
names(lulc_change) <- c("LULC_2017", "LULC_2023")

# Simple pixel-level change map
change_map <- lulc_2023 - lulc_2017
```

## Retrieve Sentinel-2-l2a images and compute NDVI

``` r

ndvi <- greenSD::get_s2a_ndvi(bbox = c(-83.087174,42.333373,-83.042542,42.358748), 
                              datetime = c("2022-08-01", "2022-09-01"), 
                              cloud_cover = 5,
                              output_bands = NULL)
```

## Get the greenspace segmentation from map tiles

``` r

# from Esri.WorldImagery map tiles 
green <- greenSD::get_tile_green(bbox = c(-83.087174,42.333373,-83.042542,42.358748), 
                                 provider = "esri",
                                 zoom = 16)

# from Sentinel-2 cloudless mosaic tiles
greenspace2 <- greenSD::get_tile_green(bbox = c(-83.087174,42.333373,-83.042542,42.358748), 
                                      zoom = 17, 
                                      provider = "eox",
                                      year = 2022)
```

## Extract values from Greenspace Seasonality Data Cube with samples

You can extract seasonal greenspace values at multiple point locations
within a city boundary.

``` r

boundary <- greenSD::check_urban_boundary(uid = 1825, plot = FALSE)
samples <- sf::st_sample(boundary, size = 50)
gs_samples <- greenSD::sample_values(samples, time = 2022)
```

## Visualize Seasonal Greenspace Dynamics as an Animated GIF

The
[`to_gif()`](https://billbillbilly.github.io/greenSD/reference/to_gif.md)
function converts a multi-band raster (e.g., greenspace bands across the
growing season) into an animated GIF for quick visual exploration.

``` r

# Load example data (or use `gs` from previous step)
sample_data <- terra::rast(system.file("extdata", "detroit_gs.tif", package = "greenSD"))

# Generate GIF
gif <- greenSD::to_gif(
  r = sample_data,
  fps = 5,
  width = 600,
  height = 600,
  axes = FALSE,
  title_prefix = paste("greenspace - Day", 1:terra::nlyr(sample_data) * 10)
)

# Display in RStudio Viewer or save
print(gif)

# To save the GIF manually:
magick::image_write(gif, "greenspace_animation.gif")
```
