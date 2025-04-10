
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

pop_ag <- terra::aggregate(pop, fact = 90, fun = "sum", na.rm = TRUE)
terra::plot(pop_ag)
# fact is an aggregation factor expressed as number of cells in each direction 
# this ensure that the population and meteorology are more or less on the same dimension
# pop <- as.data.frame(pop, xy=TRUE)
# summary(pop)

saveRDS(pop_ag, file = paste0("Output/population_", year))



rm(list = ls())
gc()


