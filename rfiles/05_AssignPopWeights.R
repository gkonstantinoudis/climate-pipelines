
# Created 02.04.2025

# Combine meteorology with population.

#-------------------------------------------------------------------------------
      
library(tidyverse)
library(terra)

# set path
path <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka"
setwd(path)

# read population
year <- 2020
pop <- readRDS(paste0("Output/population_", year))

##
##


# Arguments
# read meteorology
# metric <- c("2m_temperature", "total_precipitation", "CHIRPS_rainfall", "specific_humidity", "relative_humidity")
# define the statistic
# stat <- c("mean", "min", "max", "sum")

GetPopulationWeights <- function(metric, stat, plot = F){
  
  meteo <- readRDS(file = paste0("Output/SummaryTemporal_", metric, "_", stat, ".rds"))
  
  # the idea here is that I will find the NN to the coarse space id and sum
  meteo_xy <- meteo[,c("x", "y", "space_id")]
  meteo_xy <- meteo_xy[!duplicated(meteo_xy$space_id),]
  
  meteo_xy_sp <- vect(meteo_xy[,c("x", "y")] %>% as.matrix(), crs="+proj=longlat +datum=WGS84")
  meteo_xy_sp$space_id <- meteo_xy$space_id
  
  extr.dt <- terra::extract(pop, meteo_xy_sp)
  meteo_xy$pop <- extr.dt$lka_ppp_2020
  
  if(plot == TRUE){
    print(ggplot() +
      geom_point(data = meteo_xy, aes(x=x, y=y, col = pop), size = 4) +
      theme_bw() + scale_color_viridis_c(na.value = "red"))
    
  }
  
  ##
  ## and bring back to meteorology
  meteo <- left_join(meteo, meteo_xy[,c("space_id", "pop")], by = c("space_id" = "space_id"))
  
  
  # and remove NAs
  # meteo <- meteo[!is.na(meteo$pop),]
  
  # and store
  saveRDS(meteo, file = paste0("Output/Popweighted_Summary_", metric, "_", stat, ".rds"))
  
  return(meteo)
}

t_0 <- Sys.time()
GetPopulationWeights(metric = "2m_temperature", stat = "mean")
GetPopulationWeights(metric = "2m_temperature", stat = "min")
GetPopulationWeights(metric = "2m_temperature", stat = "max")
GetPopulationWeights(metric = "specific_humidity", stat = "mean")
GetPopulationWeights(metric = "relative_humidity", stat = "mean")
GetPopulationWeights(metric = "CHIRPS_rainfall", stat = "sum", plot = T)
t_1 <- Sys.time()
t_1 - t_0 # 5 seconds

# there are some NAs in coastal Sri Lanka, but after aggregating into the shp it should be fine. 

rm(list = ls())
dev.off()
gc()





                   