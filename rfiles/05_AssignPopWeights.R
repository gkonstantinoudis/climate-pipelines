
# Created 02.04.2025

# Combine meteorology with population.

#-------------------------------------------------------------------------------
      
##
## This code has two parts. In the first part, you select the year for which population 
## weighting is performed. This is applied for all the years of the exposure data. If you
## want to do year-specific population weighting go to the second part of the code.


library(tidyverse)
library(terra)

# set path
path <- "C:/Users/gkonstan/OneDrive - Imperial College London/ICRF Imperial/Projects/climate-pipelines/"
setwd(path)

# the function

# Arguments
# read meteorology
# metric <- c("2m_temperature", "total_precipitation", "CHIRPS_rainfall", "specific_humidity", "relative_humidity")
# define the statistic
# stat <- c("mean", "min", "max", "sum")
# plot is an argument that plots the data for quality checks
# year is null by default unless you want to have year specific population weights, then you need to specify the year
# pop is the population file as raster
# store is a logical, if TRUE the object is stored in the Output folder. 
GetPopulationWeights <- function(metric, stat, plot = F, year = NULL, pop, store = TRUE){
  
  meteo <- readRDS(file = paste0("Output/SummaryTemporal_", metric, "_", stat, ".rds"))
  
  if(!is.null(year)){
    meteo <- meteo %>% filter(yyear %in% year)
  }
  
  # the idea here is that I will find the NN to the coarse space id and sum
  meteo_xy <- meteo[,c("x", "y", "space_id")]
  meteo_xy <- meteo_xy[!duplicated(meteo_xy$space_id),]
  
  meteo_xy_sp <- vect(meteo_xy[,c("x", "y")] %>% as.matrix(), crs="+proj=longlat +datum=WGS84")
  meteo_xy_sp$space_id <- meteo_xy$space_id
  
  extr.dt <- terra::extract(pop, meteo_xy_sp)
  meteo_xy$pop <- extr.dt$pop
  
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
  
  if(store == TRUE){
    # and store
    saveRDS(meteo, file = paste0("Output/Popweighted_Summary_", metric, "_", stat, year, ".rds"))
  }
  
  return(meteo)
}


####
#### 1ST PART OF CODE: POPULATION WEIGHTING BASED ON A SINGLE YEAR.  
multiple_years <- FALSE
if(multiple_years == FALSE){
  
  ######
  # SPECIFY THE YEAR
  year <- 2020
  pop_year <- readRDS(paste0("Output/population_", year))
  
  t_0 <- Sys.time()
  GetPopulationWeights(metric = "2m_temperature", stat = "mean", pop = pop_year)
  GetPopulationWeights(metric = "2m_temperature", stat = "min", pop = pop_year)
  GetPopulationWeights(metric = "2m_temperature", stat = "max", pop = pop_year)
  GetPopulationWeights(metric = "specific_humidity", stat = "mean", pop = pop_year)
  GetPopulationWeights(metric = "relative_humidity", stat = "mean", pop = pop_year)
  GetPopulationWeights(metric = "CHIRPS_rainfall", stat = "sum", plot = T, pop = pop_year)
  t_1 <- Sys.time()
  t_1 - t_0 # 5 seconds
  
  # there are some NAs in coastal Sri Lanka, but after aggregating into the shp it should be fine. 
  
  rm(list = ls())
  dev.off()
  gc()
  
}






####
#### 2ND PART OF CODE: POPULATION WEIGHTING BASED ON DIFFERENT YEARS.  

if(multiple_years == TRUE){
  
  
  # Note that at time of writing the code, the only available population dataset were upto 2020, 
  # if the health outcome data is say until 2024, if we need year-specific population weights, 
  # then we need to make some assumptions for the year after 2020. For now I will assume that 
  # the population in 2021:2024 is the same as in 2020.
  
  ######
  # SPECIFY THE YEARS
  pop_end <- 2020
  outcome_start <- 2017
  outcome_end <- 2024
  year_pop <- c(outcome_start:pop_end, rep(pop_end, times = length((pop_end + 1):outcome_end)))
  year_outcome <- outcome_start:outcome_end
  
  pop_year <- lapply(year_pop, function(X) readRDS(paste0("Output/population_", X)))
  
  ##
  ## and now I need to loop over the GetPopulationWeights() function
  
  # need to set the loops
  list_2m_temperature_mean <- list()
  list_2m_temperature_min <- list()
  list_2m_temperature_max <- list()
  list_specific_humidity_mean <- list()
  list_relative_humidity_mean <- list()
  list_CHIRPS_rainfall_sum <- list()
  
  t_0 < Sys.time()
  for(i in 1:length(year_outcome)){
    print(i)
    list_2m_temperature_mean[[i]] <- GetPopulationWeights(metric = "2m_temperature", stat = "mean", 
                                                          pop = pop_year[[i]], year = year_outcome[i], store = FALSE)
    
    list_2m_temperature_min[[i]] <- GetPopulationWeights(metric = "2m_temperature", stat = "min", 
                                                         pop = pop_year[[i]], year = year_outcome[i], store = FALSE)
    
    list_2m_temperature_max[[i]] <- GetPopulationWeights(metric = "2m_temperature", stat = "max", 
                                                         pop = pop_year[[i]], year = year_outcome[i], store = FALSE)
    
    list_specific_humidity_mean[[i]] <- GetPopulationWeights(metric = "specific_humidity", stat = "mean", 
                                                             pop = pop_year[[i]], year = year_outcome[i], store = FALSE)
    
    list_relative_humidity_mean[[i]] <- GetPopulationWeights(metric = "relative_humidity", stat = "mean", 
                                                             pop = pop_year[[i]], year = year_outcome[i], store = FALSE)
    
    list_CHIRPS_rainfall_sum[[i]] <- GetPopulationWeights(metric = "CHIRPS_rainfall", stat = "sum", 
                                                          pop = pop_year[[i]], year = year_outcome[i], store = FALSE)
  }
  t_1 < Sys.time()
  t_1 - t_0 # less than 1 minute
  
  
  list_2m_temperature_mean <- do.call(rbind, list_2m_temperature_mean)
  metric = "2m_temperature"; stat = "mean"
  saveRDS(meteo, file = paste0("Output/Popweighted_Summary_", metric, "_", stat, year, ".rds"))
  
  list_2m_temperature_min <- do.call(rbind, list_2m_temperature_min)
  metric = "2m_temperature"; stat = "min"
  saveRDS(meteo, file = paste0("Output/Popweighted_Summary_", metric, "_", stat, year, ".rds"))
  
  list_2m_temperature_max <- do.call(rbind, list_2m_temperature_max)
  metric = "2m_temperature"; stat = "max"
  saveRDS(meteo, file = paste0("Output/Popweighted_Summary_", metric, "_", stat, year, ".rds"))
  
  metric = "specific_humidity"; stat = "mean"
  list_specific_humidity_mean <- do.call(rbind, list_specific_humidity_mean)
  saveRDS(meteo, file = paste0("Output/Popweighted_Summary_", metric, "_", stat, year, ".rds"))
  
  list_relative_humidity_mean <- do.call(rbind, list_relative_humidity_mean)
  metric = "relative_humidity"; stat = "mean"
  saveRDS(meteo, file = paste0("Output/Popweighted_Summary_", metric, "_", stat, year, ".rds"))
  
  list_CHIRPS_rainfall_sum <- do.call(rbind, list_CHIRPS_rainfall_sum)
  metric = "CHIRPS_rainfall"; stat = "sum"
  saveRDS(meteo, file = paste0("Output/Popweighted_Summary_", metric, "_", stat, year, ".rds"))
  
  rm(list = ls())
  dev.off()
  gc()
}




