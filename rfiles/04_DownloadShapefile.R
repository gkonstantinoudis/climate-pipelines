
# Created 03.04.2025

# Download shapefiles

#-------------------------------------------------------------------------------

# set path
path <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka"
setwd(path)

# libraries
library(tidyverse)
library(sf)

# Define the country ISO3 code and admin level
country_code <- "LKA"  # Change to desired country code

# Construct the GADM URL for shapefiles (adjust for different levels)
url <- sprintf("https://geodata.ucdavis.edu/gadm/gadm4.1/shp/gadm41_%s_shp.zip", country_code)

# Download the ZIP file
download.file(url, paste0(path, "/Output/shp.zip"), mode = "wb")

# Unzip the contents
unzip(paste0(path, "/Output/shp.zip"), exdir = paste0(path, "/Output/"))

# Locate the main .shp file
shp_file <- list.files(paste0(path, "/Output/"), pattern = "\\.shp$", full.names = TRUE)

# You need to define which level you are interested in
# level <- 1
# shp_string <- shp_file[str_sub(gsub(".shp", "", shp_file), -1) == level]
# 
# shp <- read_sf(shp_string)

# plot it to make sure it is fine. 
# plot(shp$geometry)


rm(list = ls())
gc()

