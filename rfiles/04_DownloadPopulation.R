
# Created 20.04.2025

# Download population

#-------------------------------------------------------------------------------

# install.packages("devtools")
# devtools::install_github("wpgp/wpgpDownloadR")

# wd
path <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka"
setwd(path)

# load package
library(wpgpDownloadR)
library(tidyverse)
library(terra)

# set the country
iso3 <- "LKA"
# set the year
year <- 2020
cov <- paste0("ppp_", year)


f <- wpgpGetCountryDataset(ISO3 = iso3, covariate = cov, destDir = "Output/") 
pop <- terra::rast(f)
terra::plot(pop)


pop <- as.data.frame(pop, xy=TRUE)
summary(pop)

saveRDS(pop, file = paste0("Output/population_", year))



rm(list = ls())
gc()


