
# Created 01.04.2025

# Download meteorology in Sri Lanka (CHIRPS)

#-------------------------------------------------------------------------------

# install.packages("chirps")
library(chirps)
library(terra)
library(tidyverse)
library(tidyr)

# set your working directory
wd <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/"
setwd(wd)

# Define the start and end date for the data
start_date <- "2017-01-01"
end_date <- "2024-12-31"
dates <- c(start_date, end_date)

# Define the spatial extent for Sri Lanka
lat_range <- seq(5, 10, by = 0.05)   # Latitude range (South to North), adjusting resolution
lon_range <- seq(78, 82, by = 0.05)  # Longitude range (West to East), adjusting resolution

# Generate a grid of all points (latitude, longitude) in the specified region
lonlat <- expand.grid(lon = lon_range, lat = lat_range)

# Download CHIRPS data for the defined extent and time period
t_0 <- Sys.time()
chirps_data <- get_chirps(lonlat, 
                          dates = dates, 
                          server = "CHC", 
                          as.matrix = TRUE)
t_1 <- Sys.time()
t_1 - t_0 # 30 minutes

chirps_data <- cbind(lonlat, chirps_data)

chirps_data[chirps_data<0] <- NA
chirps_data <- chirps_data[!is.na(chirps_data[,3]),]

con1 <- colnames(chirps_data)[-c(1:2)][1]
conn <- colnames(chirps_data)[-c(1:2)][length(colnames(chirps_data)[-c(1:2)])]

# wide to long format
data_long <- chirps_data %>%
  pivot_longer(cols = -c(1:2), names_to = "date", values_to = "precipitation")

# retrieve the date
data_long$date <- gsub("chirps-v2.0.", "", data_long$date)
data_long$date <- as.Date(data_long$date, format = "%Y.%m.%d")

# and format as the ERA5
# x  y 2m_temperature_mean       date
# 1 78.0 10            27.18777 2017-01-01
# 2 78.1 10            27.26456 2017-01-01
# 3 78.2 10            27.27495 2017-01-01
# 4 78.3 10            27.25377 2017-01-01
# 5 78.4 10            27.41208 2017-01-01
# 6 78.5 10            27.48671 2017-01-01

data_long %>% 
  dplyr::rename(
    x=lon, 
    y=lat, 
    CHIRPS_rainfall_sum = precipitation,
    date=date
  ) %>% 
  select(x, y, CHIRPS_rainfall_sum, date) -> data_long


saveRDS(data_long, file = paste0("Output/Summary_CHIRPS_rainfall_sum.rds"))


rm(list = ls())
gc()





