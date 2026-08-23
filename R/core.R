#' @title Download Greenspace Seasonality Data Cube
#' @name get_gsdc
#'
#' @description download Greenspace Seasonality Data Cube for an urban area.
#' Retrieves high-resolution greenspace seasonality data from the Sentinel-2-based
#' global dataset developed by Wu et al. (2024). Users can define a city of interest
#' using a bounding box, place name, coordinates, or unique city ID (UID).
#'
#' @param bbox `sf`, `sfc`, or a numeric vector (xmin, ymin, xmax, ymax)
#' defining the area of interest. Optional if `place`, `location`, or `UID` is provided.
#' @param place character or vector. (optional) A single line address,
#' e.g. ("1600 Pennsylvania Ave NW, Washington") or a vector of addresses
#' (c("Madrid", "Barcelona")). This can be ignored if `location` is specified.
#' @param location vector or sf point. A point of interest.
#' Ignored if `UID` is specified.
#' @param UID numeric. Urban area ID. To check the ID of an available urban area,
#' use [check_available_urban()]
#' @param year numeric. (required) The year of interest.
#' @param time Character vector of length 2 or character. (optional) Start and end dates in
#' `"MM-DD"` format (e.g., `c("03-20", "10-15")` or `"07-10"`). Used to subset the 10-day
#' interval data cube by time.
#' @param mask logical (optional). Default is `TRUE`. If `TRUE`, masks the
#' raster data using the given `bbox` or `place` if it is specified.
#' @param quiet logical. Whether show progress bars for some process.
#'
#' @return A `SpatRaster` object containing the greenspace seasonality data.
#'
#' @details
#' The Greenspace Data Cube is organized into 36 bands per year,
#' each representing a 10-day interval.
#'
#' @references
#' Wu, S., Song, Y., An, J. et al. High-resolution greenspace dynamic
#' data cube from Sentinel-2 satellites over 1028 global major cities.
#' Sci Data 11, 909 (2024). https://doi.org/10.1038/s41597-024-03746-7
#'
#' @note
#' Use [check_available_urban()] and [check_urban_boundary()] to see supported
#' cities and their boundaries.
#'
#' @examples
#' result <- get_gsdc(UID = 0,
#'                    # year = 2022
#'                   )
#'
#' @importFrom sf st_sfc st_transform st_bbox st_as_sfc st_point
#' @importFrom nominatimlite geo_lite_sf
#' @importFrom terra mask crop vect
#' @export
get_gsdc <- function(bbox = NULL, place = NULL, location = NULL, UID = NULL,
                       year = NULL, time = NULL, mask = TRUE, quiet = TRUE) {
  if (inherits(year, 'NULL')) {
    cli::cli_alert_info("`year` is missing.")
    return(NULL)
  }

  if (inherits(bbox, 'NULL') && inherits(place, 'NULL') && inherits(location, 'NULL') && inherits(UID, 'NULL')) {
    cli::cli_alert_info('Area/point of interest is missing.')
    return(NULL)
  }

  if (!as.numeric(year) %in% c(2019, 2020, 2021, 2022)) {
    stop("`year` has to be 2019, 2020, 2021, or 2022")
  }
  if (quiet) {
    terra::terraOptions(progress=0)
    on.exit(terra::terraOptions(progress=3), add = TRUE)
  }

  start_time <- Sys.time()
  urls <- NULL

  # find the city with a corresponding uid
  if(!inherits(UID, 'NULL')) {
    urls <- get_data_with_uid(UID, year)
    if (length(urls) == 0) {
      base::warning("No greenspace data found for the specified UID/year.")
      return(NULL)
    }
    greenspace <- download_data(urls)
    if (!is.null(time)) {
      if (length(time) != 1) {
        start_band_index <- get_band_index_by_time(time[1], year)
        end_band_index <- get_band_index_by_time(time[2], year)
        greenspace <- greenspace[[start_band_index:end_band_index]]
      } else {
        greenspace <- greenspace[[get_band_index_by_time(time, year)]]
      }
    }
    report_time(start_time)
    return(greenspace)
  }

  # find intersected area with a spatial point
  if (!inherits(location, 'NULL')) {
    # check type of point
    if (is.numeric(location) && length(location) == 2){
      location <- sf::st_sfc(sf::st_point(location), crs = 4326)
    }else {
      location <- sf::st_transform(location, crs = 4326)
    }
    # find the UID of overlapped city
    uid <- check_overlap(location)
    if (is.na(uid)) {
      base::warning("No urban areas intersect with the area/point of interest.")
      return(NULL)
    }
    urls <- get_data_with_uid(id = as.numeric(uid), y = year)
    if (length(urls) == 0) {
      base::warning("No greenspace data found for the matched urban area/year.")
      return(NULL)
    }
    greenspace <- download_data(urls)
    if (!is.null(time)) {
      if (length(time) != 1) {
        start_band_index <- get_band_index_by_time(time[1], year)
        end_band_index <- get_band_index_by_time(time[2], year)
        greenspace <- greenspace[[start_band_index:end_band_index]]
      } else {
        greenspace <- greenspace[[get_band_index_by_time(time, year)]]
      }
    }
    report_time(start_time)
    return(greenspace)
  }

  if (!inherits(bbox, 'NULL') || !inherits(place, 'NULL')) {
    if (!inherits(place, 'NULL')) {
      city <- suppressWarnings(nominatimlite::geo_lite_sf(place, points_only = FALSE))
      city <- sf::st_transform(city, crs = 4326)
      bbox <- city$geometry
    } else if (!inherits(bbox, 'NULL')) {
      if (is.numeric(bbox) && length(bbox) == 4) {
        bbox <- sf::st_as_sfc(
          sf::st_bbox(
            c(xmin = bbox[1],
              ymin = bbox[2],
              xmax = bbox[3],
              ymax = bbox[4]),
            crs = 4326
          )
        )
      }
    }
    bbox <- sf::st_transform(bbox, 4326)
    location <- sf::st_centroid(bbox)
    uid <- check_overlap(location)
    if (is.na(uid)) {
      base::warning("No urban areas intersect with the area/point of interest.")
      return(NULL)
    }
    urls <- get_data_with_uid(id = as.numeric(uid), y = year)
    if (length(urls) == 0) {
      base::warning("No greenspace data found for the matched urban area/year.")
      return(NULL)
    }
    greenspace <- download_data(urls)

    if (!is.null(time)) {
      if (length(time) != 1) {
        start_band_index <- get_band_index_by_time(time[1], year)
        end_band_index <- get_band_index_by_time(time[2], year)
        greenspace <- greenspace[[start_band_index:end_band_index]]
      } else {
        greenspace <- greenspace[[get_band_index_by_time(time, year)]]
      }
    }

    if (mask) {
      if (!inherits(bbox, "SpatVector")) {
        bbox_vect <- terra::vect(bbox)
      } else {
        bbox_vect <- bbox
      }
      greenspace <- terra::mask(greenspace, bbox_vect)
      greenspace <- terra::crop(greenspace, bbox_vect)
    }
    report_time(start_time)
    return(greenspace)
  }

  if (inherits(urls, 'NULL')) {
    base::warning("No urban areas intersect with the area/point of interest.")
    return(NULL)
  }
}

#' @title Download Land Cover or NDVI Data from ESA WorldCover or
#' Sentinel-2 10m Land Use/Land Cover Time Series
#' @name get_esa_wc
#'
#' @description Download 11-class land cover or 3-band NDVI data from the
#' ESA WorldCover 10m Annual Dataset (NDVI p90, NDVI p50, NDVI p10), or
#' 9-class annual land use/land cover (LULC) maps from the Sentinel-2 10m
#' Land Use/Land Cover Time Series produced by Impact Observatory, accessed
#' via Microsoft Planetary Computer. Users can define an area of interest
#' using a bounding box or place name.
#'
#' @param bbox `sf`, `sfc`, or a numeric vector (xmin, ymin, xmax, ymax)
#' defining the area of interest. Optional if `place` is provided.
#' @param place character or vector. (optional) A single line address,
#' e.g. ("1600 Pennsylvania Ave NW, Washington") or a vector of addresses
#' (c("Madrid", "Barcelona")).
#' @param datatype character. One of `"landcover"`, `"ndvi"`, or `"lulc"`.
#' `"landcover"` and `"ndvi"` retrieve ESA WorldCover data (years 2020–2021).
#' `"lulc"` retrieves the Sentinel-2 10m LULC Time Series (years 2017–2024).
#' @param year numeric. The year of interest. For `"landcover"` and `"ndvi"`:
#' `2020` or `2021` (default `2021`). For `"lulc"`: an integer from `2017`
#' to `2024`.
#' @param mask logical (optional). Default is `TRUE`. If `TRUE`, masks the
#' raster data using the given `bbox` or `place`.
#' @param quiet logical. Whether show progress bars for some process.
#'
#' @return A `SpatRaster` object. For `"landcover"`: 11-class ESA WorldCover
#' land cover map. For `"ndvi"`: NDVI yearly percentile composite
#' (NDVI p90, NDVI p50, NDVI p10). For `"lulc"`: 9-class Sentinel-2
#' annual land use/land cover classification (layer named `"LULC"`).
#'
#' @details
#' The `"lulc"` datatype retrieves the Impact Observatory Sentinel-2 10m
#' Land Use/Land Cover Time Series from the public AWS open data bucket
#' (`s3://io-10m-annual-lulc`, no authentication required). New annual maps
#' are released each January, so coverage currently extends to 2024. The 9
#' classes are:
#' 1 = Water, 2 = Trees, 4 = Flooded vegetation, 5 = Crops,
#' 7 = Built area, 8 = Bare ground, 9 = Snow/ice, 10 = Clouds,
#' 11 = Rangeland.
#'
#' @examples
#' \donttest{
#' # ESA WorldCover land cover
#' result <- get_esa_wc(
#'   place = 'New York',
#'   datatype = 'landcover',
#'   year = 2021
#' )
#'
#' # Sentinel-2 10m LULC Time Series
#' result <- get_esa_wc(
#'   place = 'New York',
#'   datatype = 'lulc',
#'   year = 2022
#' )
#' }
#'
#' @references
#' Zanaga, D., Van De Kerchove, R., De Keersmaecker, W., Souverijns, N.,
#' Brockmann, C., Quast, R., Wevers, J., Grosu, A., Paccini, A., Vergnaud, S.,
#' Cartus, O., Santoro, M., Fritz, S., Georgieva, I., Lesiv, M., Carter, S.,
#' Herold, M., Li, L., Tsendbazar, N.-E., … Arino, O. (2021).
#' ESA WorldCover 10 m 2020 v100 (Version v100).
#' Zenodo. https://doi.org/10.5281/zenodo.5571936
#'
#' Zanaga, D., Van De Kerchove, R., Daems, D., De Keersmaecker, W., Brockmann,
#' C., Kirches, G., Wevers, J., Cartus, O., Santoro, M., Fritz, S., Lesiv, M.,
#' Herold, M., Tsendbazar, N.-E., Xu, P., Ramoino, F., & Arino, O. (2022).
#' ESA WorldCover 10 m 2021 v200 (Version v200).
#' Zenodo. https://doi.org/10.5281/zenodo.7254221
#'
#' Karra, K., Kontgis, C., Statman-Weil, Z., Mazzariello, J. C., Mathis, M.,
#' & Brumby, S. P. (2021). Global land use / land cover with Sentinel-2 and
#' deep learning. IGARSS 2021.
#' https://doi.org/10.1109/IGARSS47720.2021.9553499
#'
#' @importFrom aws.s3 get_bucket save_object
#' @export
get_esa_wc <- function(bbox = NULL, place = NULL,
                       datatype = "landcover",
                       year = 2021, mask = TRUE,
                       quiet = TRUE) {
  if (!datatype %in% c("landcover", "ndvi", "lulc")) {
    stop("`datatype` must be one of 'landcover', 'ndvi', or 'lulc'.")
  }
  if (datatype %in% c("landcover", "ndvi")) {
    if (!as.numeric(year) %in% c(2020, 2021)) {
      stop("`year` has to be 2020 or 2021 for ESA WorldCover 'landcover' and 'ndvi' data.")
    }
  } else if (datatype == "lulc") {
    if (!as.numeric(year) %in% 2017:2024) {
      stop("`year` has to be between 2017 and 2024 for Sentinel-2 LULC Time Series data.")
    }
  }

  start_time <- Sys.time()

  if (!inherits(bbox, 'NULL') || !inherits(place, 'NULL')) {
    if (!inherits(place, 'NULL')) {
      pla <- suppressWarnings(nominatimlite::geo_lite_sf(place, points_only = FALSE))
      pla <- sf::st_transform(pla, crs = 4326)
      bbox <- pla$geometry
    } else if (!inherits(bbox, 'NULL')) {
      if (is.numeric(bbox) && length(bbox) == 4) {
        bbox <- sf::st_as_sfc(
          sf::st_bbox(
            c(xmin = bbox[1],
              ymin = bbox[2],
              xmax = bbox[3],
              ymax = bbox[4]),
            crs = 4326
          )
        )
      }
    }
  } else {
    return(NULL)
  }
  bbox <- sf::st_transform(bbox, 4326)
  bbox_coords <- sf::st_bbox(bbox)

  # --- Sentinel-2 10m LULC Time Series (Impact Observatory public S3) ---
  if (datatype == "lulc") {
    cli::cli_alert_info("Searching for Sentinel-2 LULC tiles ...")

    # Query Impact Observatory's own public STAC service (no auth required)
    items <- rstac::stac("https://api.impactobservatory.com/stac-aws/") %>%
      rstac::stac_search(
        collections = "io-10m-annual-lulc",
        bbox = c(bbox_coords["xmin"], bbox_coords["ymin"],
                 bbox_coords["xmax"], bbox_coords["ymax"]),
        datetime = paste0(year, "-01-01T00:00:00Z/", year, "-12-31T23:59:59Z"),
        limit = 100
      ) %>%
      rstac::get_request()

    features <- items$features
    n_items <- length(features)

    if (n_items == 0) {
      cli::cli_alert_info("No Sentinel-2 LULC tiles found for the requested area/year.")
      return(NULL)
    }

    cli::cli_alert_info(paste0("Downloading ", n_items, " Sentinel-2 LULC tile(s) ..."))

    result_list <- list()
    temp_paths <- c()
    original_timeout <- getOption('timeout')
    options(timeout = 9999)
    on.exit({
      options(timeout = original_timeout)
      unlink(temp_paths, recursive = TRUE)
    }, add = TRUE)

    for (i in seq_len(n_items)) {
      # resolve the href: "supercell" is the asset key for io-10m-annual-lulc;
      # fall back to first available asset if key changes in future versions
      assets <- features[[i]]$assets
      href <- if (!is.null(assets$supercell$href)) {
        assets$supercell$href
      } else {
        assets[[1]]$href
      }
      # convert s3:// URI to HTTPS if needed (href is usually already HTTPS)
      href <- sub("^s3://io-10m-annual-lulc/",
                  "https://io-10m-annual-lulc.s3.us-west-2.amazonaws.com/",
                  href)
      temp_tif <- tempfile(fileext = ".tif")
      utils::download.file(href, temp_tif, mode = "wb", quiet = quiet)
      result_list[[i]] <- terra::rast(temp_tif)
      temp_paths <- c(temp_paths, temp_tif)
    }

    cli::cli_alert_success("Finished downloading data")

    if (length(result_list) == 1) {
      out_data <- result_list[[1]]
    } else {
      cli::cli_alert_info("Mosaicing multiple tiles ...")
      rast_collection <- terra::sprc(result_list)
      out_data <- terra::mosaic(rast_collection, fun = "first")
    }

    out_data <- terra::project(out_data, "EPSG:4326", method = "near")

    if (mask) {
      cli::cli_alert_info("Masking and cropping data ...")
      bbox_vect <- if (!inherits(bbox, "SpatVector")) terra::vect(bbox) else bbox
      out_data <- terra::mask(out_data, bbox_vect)
      out_data <- terra::crop(out_data, bbox_vect)
    }

    names(out_data) <- "LULC"
    cli::cli_alert_success("Data successfully processed.")
    report_time(start_time)
    return(out_data)
  }

  # --- ESA WorldCover (landcover / ndvi) ---

  # List ESA Tile Names by bbox
  tiles <- if (datatype == 'landcover') {
    esa_wc_tiles[sf::st_intersects(esa_wc_tiles, bbox, sparse = FALSE), ]$tile
  } else if (datatype == 'ndvi') {
    get_esa_tile_names(
      lat_min = bbox_coords["ymin"], lat_max = bbox_coords["ymax"],
      lon_min = bbox_coords["xmin"], lon_max = bbox_coords["xmax"]
    )
  }
  if (length(tiles) == 0) {
    cli::cli_alert_info("No ESA WorldCover tiles intersect the requested area.")
    return(NULL)
  }

  # get tiles
  keys <- c()
  for (i in seq_along(tiles)) {
    t <- tiles[i]
    if (datatype == 'landcover') {
      f <- paste0(if (year == 2020) "v100/2020/" else "v200/2021/",
                  'map/ESA_WorldCover_10m_',
                  if (year == 2020) '2020_v100_' else '2021_v200_',
                  t, "_Map.tif")
      keys <- c(keys, f)
    } else if (datatype == 'ndvi') {
      f <- aws.s3::get_bucket(
        bucket = "esa-worldcover-s2",
        region = "eu-central-1",
        prefix = paste0('ndvi/',
                        year, '/',
                        base::strsplit(t, "W")[[1]][1],
                        '/ESA_WorldCover_10m_',
                        year, '_v200_', t, '_NDVI'),
        max = Inf
      )
      f <- tibble::tibble(
        key = vapply(f, function(x) x[["Key"]], character(1)),
      )

      keys <- c(keys, as.character(f$key))
    }
  }
  if (length(keys) == 0) {
    cli::cli_alert_info("No ESA WorldCover data found for the requested area/year/datatype.")
    return(NULL)
  }

  # download data
  result_list <- list()
  temp_paths <- c()
  original_timeout <- getOption('timeout')
  options(timeout=9999)
  on.exit({
    options(timeout = original_timeout)
    unlink(temp_paths, recursive = TRUE)
  }, add = TRUE)
  cli::cli_alert_info(
    paste0("Start downloading ",
           if (datatype == 'landcover') 'land cover ' else 'NDVI ',
           "data ...")
  )
  for (i in seq_along(keys)) {
    k <- keys[i]
    temp_tif <- tempfile(fileext = ".tif")
    if (datatype == 'landcover') {
      aws.s3::save_object(
        object = k,
        bucket = "esa-worldcover",
        region = "eu-central-1",
        file = temp_tif
      )
    } else if (datatype == 'ndvi') {
      aws.s3::save_object(k,
                          bucket = "esa-worldcover-s2",
                          region = "eu-central-1",
                          file = temp_tif)
    }
    rast_data <- terra::rast(temp_tif)
    result_list[[length(result_list) + 1]] <- rast_data
    temp_paths <- c(temp_paths, temp_tif)
  }
  cli::cli_alert_success('Finished downloading data')

  # merge if there are multiple tiles
  if (length(result_list) == 1) {
    out_data <- result_list[[1]]
  } else {
    cli::cli_alert_info('Merging multiple tiles ...')
    out_data <- do.call(terra::merge, result_list)
  }

  # crop the raster
  if (mask) {
    cli::cli_alert_info('Masking and cropping data ...')
    if (!inherits(bbox, "SpatVector")) {
      bbox_vect <- terra::vect(bbox)
    } else {
      bbox_vect <- bbox
    }
    out_data <- terra::mask(out_data, bbox_vect)
    out_data <- terra::crop(out_data, bbox_vect)
  }
  if (datatype == "ndvi") names(out_data) <- c("NDVI_p90", "NDVI_p50", "NDVI_p10")
  cli::cli_alert_success("Data successfully processed.")
  report_time(start_time)
  return(out_data)
}

#' @title Retrieve Sentinel-2-l2a images to compute NDVI
#' @name get_s2a_ndvi
#' @description download Sentinel-2-l2a imagery data and compute NDVI.
#' Users can define an area of interest using a bounding box or place name.
#'
#' @param bbox `sf`, `sfc`, or a numeric vector (xmin, ymin, xmax, ymax)
#' defining the area of interest. Optional if `place` is provided.
#' @param place character or vector. (optional) A single line address,
#' e.g. ("1600 Pennsylvania Ave NW, Washington") or a vector of addresses
#' (c("Madrid", "Barcelona")).
#' @param datetime numeric vector of 2. The time of interest such as
#' `c("2020-08-01", "2020-09-01")`.
#' @param cloud_cover numeric. Threshold for the percentage of cloud coverage.
#' Desfault is 10.
#' @param vege_perc numeric. Threshold for the percentage of vegetation coverage.
#' Desfault is 0.
#' @param select character. one of "latest", "earliest", "all". The default
#' is "latest".
#' @param method character. A method for mosaicing layers: one of "mean",
#' "median", "min", "max", "modal", "sum", "first", "last". The default
#' is "first".
#' @param mask logical (optional). Default is `TRUE`. If `TRUE`, masks the
#' raster data using the given `bbox` or `place`.
#' @param output_bands vector. A list of band names (`c('B04', 'B08')`).
#' The default is `NULL`. If `output_bands` is specified, NDVI will not
#' be computed and only the specified bands will be returned.
#' All available bands can be found [here](https://docs.sentinel-hub.com/api/latest/data/sentinel-2-l2a/#available-bands-and-data)
#' @param quiet logical. Whether show progress bars for some process.
#'
#' @return
#' A `SpatRaster` object containing (multiple) NDVI layer(s) (for different
#' period of time) `select = "latest"` or `select = "first"`
#' (or if `mask = TRUE` and `select = "all"`)
#'
#' A `List` of NDVI rasters if `mask = FALSE` and `select = "all"`.
#'
#' @examples
#' \donttest{
#' result <- get_s2a_ndvi(
#'   place = 'New York',
#'   datetime = c("2020-08-01", "2020-09-01")
#' )
#' }
#' @export
get_s2a_ndvi <- function(bbox = NULL, place = NULL, datetime = c(),
                         cloud_cover = 10, vege_perc = 0, select = "latest",
                         method = 'first', mask = TRUE,
                         output_bands = NULL, quiet = TRUE) {
  if (quiet) {
    terra::terraOptions(progress=0)
    on.exit(terra::terraOptions(progress=3), add = TRUE)
  }

  start_time <- Sys.time()

  if (!inherits(bbox, 'NULL') || !inherits(place, 'NULL')) {
    if (!inherits(place, 'NULL')) {
      pla <- suppressWarnings(nominatimlite::geo_lite_sf(place, points_only = FALSE))
      pla <- sf::st_transform(pla, crs = 4326)
      bbox <- pla$geometry
    } else if (!inherits(bbox, 'NULL')) {
      if (is.numeric(bbox) && length(bbox) == 4) {
        bbox <- sf::st_as_sfc(
          sf::st_bbox(
            c(xmin = bbox[1],
              ymin = bbox[2],
              xmax = bbox[3],
              ymax = bbox[4]),
            crs = 4326
          )
        )
      }
    }
  } else {
    return(NULL)
  }
  bbox <- sf::st_transform(bbox, 4326)

  if (length(datetime) <= 1) {
    stop("missing `datetime`")
  }

  cli::cli_alert_info('Start downloading data ...')
  features <- download_sentinel(bbox, datetime[1], datetime[2],
                                cloud_cover = cloud_cover, vege_perc = vege_perc)
  if (length(features) == 0) {
    cli::cli_alert_info("No Sentinel-2 L2A scenes found for the requested filters.")
    return(NULL)
  }

  dates <- c()
  for (i in seq_along(features)) {
    dates <- c(dates, strsplit(features[[i]]$properties$datetime, split = "T")[[1]][1])
  }
  dates <- unique(dates)

  select_date <- NULL
  ndvi_list <- list()
  band_list <- list()
  bands <- list()
  for (b in output_bands) {
    bands[[b]] <- list()
  }
  for (d in dates) {
    ndvi_list[[d]] <- list()
    band_list[[d]] <- bands
  }
  if (select == "latest" || select == "earliest") {
    select_date <- get_the_date(select, dates)
  }
  cli::cli_alert_info('Importing bands ...')
  for (i in seq_along(features)) {
    this_date <- strsplit(features[[i]]$properties$datetime, split = "T")[[1]][1]
    if (!is.null(select_date) && isTRUE(this_date != select_date)) {
      next
    }
    signed_item <- rstac::sign_planetary_computer()(features[[i]])
    if (!is.null(output_bands)) {
      for (b in output_bands) {
        url <- signed_item$assets[[b]]$href
        temp <- terra::rast(url)
        names(temp) <- b
        band_list[[this_date]][[b]][[length(band_list[[this_date]][[b]])+1]] <- temp
      }
    } else {
      b4_url <- signed_item$assets$B04$href
      b8_url <- signed_item$assets$B08$href
      b04_rast <- terra::rast(b4_url)
      b08_rast <- terra::rast(b8_url)
      ndvi <- compute_ndvi(b04_rast, b08_rast)
      names(ndvi) <- paste0('NDVI_', this_date)
      ndvi_list[[this_date]][[length(ndvi_list[[this_date]])+1]] <- ndvi
    }
  }
  cli::cli_alert_info(if (mask) 'Mosaicing, masking and cropping ...' else 'Mosaicing ...')
  if (mask) {bbox_vect <- terra::vect(bbox)}
  for (d in dates) {
    if (!is.null(select_date) && isTRUE(d != select_date)) {
      next
    }
    if (!is.null(output_bands)) {
      for (b in output_bands) {
        band_collection <- terra::sprc(band_list[[d]][[b]])
        band_mosaic <- terra::mosaic(band_collection, fun = method)
        band_list[[d]][[b]] <- terra::project(band_mosaic, 'EPSG:4326', method = 'bilinear')
        if (mask) {
          band_list[[d]][[b]] <- terra::mask(band_list[[d]][[b]], bbox_vect)
          band_list[[d]][[b]] <- terra::crop(band_list[[d]][[b]], bbox_vect)
        }
      }
      ndvi_list[[d]] <- terra::rast(band_list[[d]][output_bands])
    } else {
      ndvi_collection <- terra::sprc(ndvi_list[[d]])
      ndvi_mosaic <- terra::mosaic(ndvi_collection, fun = method)
      ndvi_list[[d]] <- terra::project(ndvi_mosaic, 'EPSG:4326', method = 'near')
      if (mask) {
        ndvi_list[[d]] <- terra::mask(ndvi_list[[d]], bbox_vect)
        ndvi_list[[d]] <- terra::crop(ndvi_list[[d]], bbox_vect)
      }
    }
  }
  if (!is.null(select_date)) {
    cli::cli_alert_success("Data successfully processed.")
    report_time(start_time)
    return(ndvi_list[[select_date]])
  }
  if (mask) {
    ndvi_list <- terra::rast(ndvi_list)
  }
  cli::cli_alert_success("Data successfully processed.")
  report_time(start_time)
  return(ndvi_list)
}


#' @title Sample greenspace-realted data from Greenspace Seasonality Data Cube,
#' ESA WorldCover 10m Annual Composites Dataset, or Sentinel-2-l2a images.
#' @name sample_values
#'
#' @description Samples values by locatoins from the Greenspace Seasonality Data Cube
#' developed by Wu et al. (2024), ESA WorldCover 10m Annual Composites Dataset
#' by Zanaga et al. (2021), or Sentinel-2-l2a images.
#'
#' @param samples A list, matrix, `data.frame`, or `sf` object of point locations.
#' Can be a list of length-2 numeric vectors (`list(c(lon, lat))`),
#' a 2-column matrix or data.frame, or an `sf` object with POINT geometry in any CRS.
#' @param time numeric or vector. The time of interest. See Detail.
#' @param year numeric or vector. Deprecated alias for `time`.
#' @param source character. The data source for extracting greenspace values:
#' `gsdc` for Greenspace Seasonality Data Cube (also see [get_gsdc()]]),
#' `esa_ndvi`or `esa_landcover` for ESA WorldCover 10m Annual Dataset
#' (also see [get_esa_wc()]]), and `s2a_ndvi` or `s2a_bands` for
#' Sentinel-2-l2a image data (also see [get_s2a_ndvi()]]). The default is `gsdc`.
#' @param output_bands vector. A list of band names (`c('B04', 'B08')`).
#' The default is `NULL`. (Only required, when `source = "s2a_bands"`)
#' All available bands can be found [here](https://docs.sentinel-hub.com/api/latest/data/sentinel-2-l2a/#available-bands-and-data)
#' @param cloud_cover numeric. The percentage of cloud coverage for retrieving
#' Sentinel-2-l2a images. (Only required, when `source = "s2a_ndvi"` or `source = "s2a_bands"`)
#' @param vege_perc numeric. The percentage of cloud coverage for retrieving
#' Sentinel-2-l2a images. (Only required, when `source = "s2a_ndvi"` or `source = "s2a_bands"`)
#' @param select character. one of "latest", "earliest", "all". The default
#' is "latest".
#' @param method character. A method for mosaicing layers: one of "mean",
#' "median", "min", "max", "modal", "sum", "first", "last". The default
#' is "first".
#' @param quiet logical. Whether show progress bars for some process.
#'
#' @return A `data.frame` containing greenspace values extracted at each point
#' across all bands. Each row corresponds to a sample location;
#' columns represent band values.
#'
#' @details
#' `time`: For the greenspace seasonality data cube, only years from 2019 to 2022
#'  are availabe. For ESA WorldCover 10m Annual Composites Dataset, only 2020
#'  and 2021 are available.
#'
#' @note
#' For sampling data from Greenspace Seasonality Data Cube `samples` must be
#' located within the same boundary of an available city in the data cube.
#' Use [check_available_urban()] and [check_urban_boundary()] to see supported
#' cities and their boundaries.
#'
#' @examples
#' \dontrun{
#' # see supported urban areas and their boundaries
#' check_available_urban()
#' boundary <- check_urban_boundary(uid = 11, plot = FALSE)
#'
#' # sample locations within the boundary
#' samples <- sf::st_sample(boundary, size = 20)
#'
#' # extract values
#' gs_samples <- sample_values(samples, time = 2022)
#' }
#'
#' @references
#' Wu, S., Song, Y., An, J. et al. High-resolution greenspace dynamic
#' data cube from Sentinel-2 satellites over 1028 global major cities.
#' Sci Data 11, 909 (2024). https://doi.org/10.1038/s41597-024-03746-7
#'
#' Zanaga, D., Van De Kerchove, R., De Keersmaecker, W., Souverijns, N.,
#' Brockmann, C., Quast, R., Wevers, J., Grosu, A., Paccini, A., Vergnaud, S.,
#' Cartus, O., Santoro, M., Fritz, S., Georgieva, I., Lesiv, M., Carter, S.,
#' Herold, M., Li, L., Tsendbazar, N.-E., … Arino, O. (2021).
#' ESA WorldCover 10 m 2020 v100 (Version v100).
#' Zenodo. https://doi.org/10.5281/zenodo.5571936
#'
#' Zanaga, D., Van De Kerchove, R., Daems, D., De Keersmaecker, W., Brockmann,
#' C., Kirches, G., Wevers, J., Cartus, O., Santoro, M., Fritz, S., Lesiv, M.,
#' Herold, M., Tsendbazar, N.-E., Xu, P., Ramoino, F., & Arino, O. (2022).
#' ESA WorldCover 10 m 2021 v200 (Version v200).
#' Zenodo. https://doi.org/10.5281/zenodo.7254221
#'
#' @importFrom sf st_drop_geometry
#' @importFrom terra extract vect
#' @export
sample_values <- function(samples = NULL, time = NULL, year = NULL,
                          source = 'gsdc', output_bands = NULL,
                          cloud_cover = 10, vege_perc = 0,
                          select = "latest", method = 'first',
                          quiet = TRUE) {
  if (is.null(time) && !is.null(year)) {
    time <- year
  }
  if (is.null(time)) {
    return(NULL)
  }

  if (quiet) {
    terra::terraOptions(progress=0)
    on.exit(terra::terraOptions(progress=3), add = TRUE)
  }

  # Convert samples to sf POINTs
  if (inherits(samples, "sf")) {
    sf_points <- sf::st_transform(samples, 4326)
  } else if (is.list(samples)) {
    coords <- do.call(rbind, samples)
    sf_points <- sf::st_as_sf(data.frame(x = coords[,1], y = coords[,2]),
                              coords = c("x", "y"), crs = 4326)
  } else if (is.matrix(samples) || is.data.frame(samples)) {
    if (ncol(samples) != 2) stop("`samples` must have two columns: lon and lat.")
    sf_points <- sf::st_as_sf(data.frame(x = samples[,1], y = samples[,2]),
                              coords = c("x", "y"), crs = 4326)
  } else {
    stop("`samples` must be a list, matrix, data.frame, or sf POINT object.")
  }

  # Get bounding box and pad slightly to ensure coverage
  bbox <- as.numeric(sf::st_bbox(sf_points)) + c(-0.01, -0.01, 0.01, 0.01)

  # Retrieve raster data
  if (source == 'gsdc') {
    raster_data <- get_gsdc(bbox = bbox, year = time, mask = FALSE)
  } else if (source == 'esa_ndvi') {
    raster_data <- get_esa_wc(bbox = bbox, datatype = 'ndvi', year = time, mask = FALSE)
  } else if (source == 'esa_landcover') {
    raster_data <- get_esa_wc(bbox = bbox, datatype = 'landcover', year = time, mask = FALSE)
  } else if (source == 's2a_ndvi') {
    raster_data <- get_s2a_ndvi(bbox = bbox, datetime = time,
                 cloud_cover = cloud_cover,
                 vege_perc = vege_perc,
                 select = select,
                 method = method,
                 mask = FALSE)
  } else if (source == 's2a_bands')
    raster_data <- get_s2a_ndvi(bbox = bbox, datetime = time,
                 cloud_cover = cloud_cover,
                 vege_perc = vege_perc,
                 select = select,
                 method = method,
                 mask = FALSE,
                 output_bands = output_bands)
  if (is.null(raster_data)) {
    cli::cli_alert_warning("No raster data found for the specified location/year.")
    return(NULL)
  }

  # Extract values at point locations
  values <- terra::extract(raster_data, terra::vect(sf_points))

  # Combine with coordinates (omit ID column)
  result <- sf::st_drop_geometry(sf_points)
  result <- cbind(result, values[, -1, drop = FALSE])

  return(result)
}

#' @title Classify greenspace based on map tile images
#' @name get_tile_green
#' @description
#' Generate high-resolution greenspace segmentation using WorldImagery map
#' tiles provided by esri and Sentinel-2 cloudless mosaic tiles provided
#' by EOX.
#' @param bbox `sf`, `sfc`, or a numeric vector (xmin, ymin, xmax, ymax)
#' defining the area of interest. Optional if `place` is provided.
#' @param place character or vector. (optional) A single line address,
#' e.g. ("1600 Pennsylvania Ave NW, Washington") or a vector of addresses
#' (c("Madrid", "Barcelona")).
#' @param zoom numeric. Zoom level of map tile. The default is `17`.
#' @param provider character. One of "esri" and "eox".
#' @param year integer. The desired year for Sentinel-2 cloudless mosaic
#' tiles. (This is required when `provider = "eox"`)
#' @param bright_filter numeric. To remove very bright pixels (concrete,
#' roofs, glare) Default is 0.85. With lower `bright_filter`, more bright
#' pixels will be excluded.
#' @param gr_ratio_filter numeric. (range from 0 to 1) To exclude pixels
#' where green is only microscopically bigger than red. Default is 0.05.
#' With higher `gr_ratio_filter`, more pixels will be excluded.
#' @param gb_ratio_filter numeric. (range from 0 to 1) To exclude pixels
#' where green is only microscopically bigger than blue. Default is 0.05.
#' With higher `gb_ratio_filter`, more pixels will be excluded.
#' @param clean logical. Whether to remove the blight and less green pixels
#' based on `bright_filter`, `gr_ratio_filter`, and `gb_ratio_filter`.
#' @param quiet logical. Whether show progress bars for some process.
#'
#' @return
#' A list of two rasters including: greenspace segmentation (where 1 is
#' green and 0 is non-green) and original map tiles
#'
#' @note
#' The data derived from Esri WorldImagery may need to include appropriate
#' Esri copyright notice.
#'
#' @examples
#' g <- get_tile_green(
#'  # bbox = c(-83.087174,42.333373,-83.042542,42.358748),
#'  zoom = 15
#' )
#'
#' @importFrom maptiles create_provider get_tiles
#' @importFrom terra as.array
#' @export
get_tile_green <- function(bbox = NULL,
                           place = NULL,
                           zoom = 17,
                           provider = 'esri',
                           year = NULL,
                           bright_filter = 0.85,
                           gr_ratio_filter = 0.05,
                           gb_ratio_filter = 0.05,
                           clean = TRUE,
                           quiet = TRUE) {
  if (quiet) {
    terra::terraOptions(progress=0)
    on.exit(terra::terraOptions(progress=3), add = TRUE)
  }
  start_time <- Sys.time()

  if (!inherits(bbox, 'NULL') || !inherits(place, 'NULL')) {
    if (!inherits(place, 'NULL')) {
      pla <- suppressWarnings(nominatimlite::geo_lite_sf(place, points_only = FALSE))
      pla <- sf::st_transform(pla, crs = 4326)
      bbox <- pla$geometry
    } else if (!inherits(bbox, 'NULL')) {
      if (is.numeric(bbox) && length(bbox) == 4) {
        bbox <- sf::st_as_sfc(
          sf::st_bbox(
            c(xmin = bbox[1],
              ymin = bbox[2],
              xmax = bbox[3],
              ymax = bbox[4]),
            crs = 4326
          )
        )
      }
    }
  } else {
    return(NULL)
  }
  bbox <- sf::st_transform(bbox, 4326)
  if (provider == "eox" & is.null(year)) stop("`year` is missing.")
  cli::cli_alert_info(paste0('Downloading ',
                             if (provider == "eox") "Sentinel-2 cloudless mosaic " else "Esri.WorldImagery "
                             ,'map tiles ...'))
  if (provider == "eox") {
    xml_text <- write_eox_wms_xml(bbox = sf::st_bbox(bbox), year = year, zoom = zoom)
    temp_xml <- tempfile(fileext = ".xml")
    on.exit(unlink(temp_xml))
    writeLines(xml_text, temp_xml)
    m <- terra::rast(temp_xml)
    mat <- terra::as.array(m)
    m <- terra::rast(mat, extent = terra::ext(m), crs = terra::crs(m))
  } else {
    m <- maptiles::get_tiles(bbox,
                             provider = "Esri.WorldImagery",
                             zoom = zoom,
                             crop = TRUE)
  }

  names(m) <- c('r', 'g', 'b')
  t <- m/255

  # The code below was done by Xiaojiang Li,
  # Ian Seiferling, Marwa Abdulhai, Senseable City Lab, MIT
  redThreImgU <- t[[1]] < 0.6
  greenThreImgU <- t[[2]] < 0.9
  blueThreImgU <- t[[3]] < 0.6
  shadowRedU <- t[[1]] < 0.3
  shadowGreenU <- t[[2]] < 0.3
  shadowBlueU <- t[[3]] < 0.3

  greenImg1 <- redThreImgU * blueThreImgU * greenThreImgU
  greenImgShadow1 <- shadowRedU * shadowGreenU * shadowBlueU

  threImgU <-  redThreImgU * blueThreImgU * greenThreImgU
  imgShadow <- shadowRedU * shadowGreenU * shadowBlueU

  g_r_dif <- t[[2]] - t[[1]]
  g_b_dif <- t[[2]] - t[[3]]
  ExG <- g_r_dif + g_b_dif
  diffImg <- g_r_dif * g_b_dif

  threshold <- 0.5
  greenImg3 <- diffImg > 0.0
  greenImg4 <- g_r_dif > 0

  threshold <- graythresh(ExG, 0.1)
  if (threshold > 0.1) {
    threshold <- 0.1
  } else if (threshold < 0.05) {
    threshold <- 0.05
  }

  # G must be dominant
  greenImg2 <- ExG > threshold
  greenImgShadow2 = ExG > 0.05
  greenImg <- greenImg1*greenImg2 + greenImgShadow2*greenImgShadow1

  g_dom <- (t[[2]] > t[[1]]) & (t[[2]] > t[[3]])
  # green advantage ratio over red / blue
  eps <- 1e-6
  gr_ratio <- (t[[2]] - t[[1]]) / (t[[2]] + t[[1]] + eps)
  gb_ratio <- (t[[2]] - t[[3]]) / (t[[2]] + t[[3]] + eps)
  # knock out very bright pixels (concrete, roofs, glare)
  not_bright <- !((t[[1]] > bright_filter) & (t[[2]] > bright_filter) & (t[[3]] > bright_filter))

  if (clean) {
    greenImg <- (greenImg != 0) &
      g_dom &
      (gr_ratio > gr_ratio_filter) &
      (gb_ratio > gb_ratio_filter) &
      not_bright

  }
  greenImg <- terra::ifel(greenImg != 0, 1, 0)

  names(greenImg) <- "green"
  map_mask <- terra::ifel(greenImg == 0, NA, m)
  output <- list(green = greenImg,
                 map = m)
  report_time(start_time)
  return(output)
}
