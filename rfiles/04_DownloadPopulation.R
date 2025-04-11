
# Created 20.04.2025

# Download population

#-------------------------------------------------------------------------------

# install.packages("devtools")
# devtools::install_github("wpgp/wpgpDownloadR")

# wd
path <- "C:/Users/gkonstan/OneDrive - Imperial College London/ICRF Imperial/Projects/climate-pipelines/"
setwd(path)

# load package
library(wpgpDownloadR)
library(tidyverse)
library(terra)

# set the country
iso3 <- "LKA"
# set the years
year <- 2017:2020
cov <- paste0("ppp_", year)

f <- lapply(cov, function(X) wpgpGetCountryDataset(ISO3 = iso3, covariate = X, destDir = "Output/") )
pop <- lapply(f, terra::rast)
terra::plot(pop[[1]])

pop_ag <- lapply(pop, terra::aggregate, fact = 90, fun = "sum", na.rm = TRUE)
terra::plot(pop_ag[[1]])
# fact is an aggregation factor expressed as number of cells in each direction 
# this ensure that the population and meteorology are more or less on the same dimension
# pop <- as.data.frame(pop, xy=TRUE)
# summary(pop)

for(i in 1:length(year)){
  names(pop_ag[[i]]) <- "pop"
  saveRDS(pop_ag[[i]], file = paste0("Output/population_", year[i]))
}


rm(list = ls())
gc()


