
# Created 07.04.2025

# Get temporal statistic based on the outcome data

#-------------------------------------------------------------------------------

library(tidyverse)
library(FNN)

# set path
path <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka"
setwd(path)

# read meteorology
# define the metric
metric <- "CHIRPS_rainfall"
# c("2m_temperature", "total_precipitation", "CHIRPS_rainfall", "specific_humidity", "relative_humidity")

# define the statistic
# Note that for temperature can be min, mean and max
# For rainfall I calculated the daily sum in the 02_CleanMeteorology file, so makes sense if its sum.
# For "specific_humidity" & "relative_humidity" this needs to be mean, as I calculated the mean
stat <- "sum"
# mean, min, max and sum

##
## Regardless of this stat, I calculated the mean of the temporal aggregation selected for everything
# For instance: Although I have calculated sum of daily precipitation, this code selected a temporal aggregation, 
# say week, and will calculate the mean weekly of the daily sum precipitation. The code gives you also the option 
# to calculate the sum, but i selected the mean. 

meteo <- readRDS(paste0("Output/Summary_", metric, "_", stat, ".rds"))
colnames(meteo)[colnames(meteo) %in% paste0(metric, "_", stat)] <- "variable"
meteo$date <- as.Date(meteo$date)

##
## get temporal statistics

# temporal <- "daily", "weekly", "monthly" and "yearly"
# weekly_stat <- "mean" or "sum"
# week_type <- "epiweek" or "isoweek" or "another"
# if it is another needs to be an excel file with the following stucture!
# wweek yyear       date
# 1     1  2000 1999-12-27
# 2     1  2000 1999-12-28
# 3     1  2000 1999-12-29
# 4     1  2000 1999-12-30
# 5     1  2000 1999-12-31
# 6     1  2000 2000-01-01


TemporalStat <- function(temporal, weekly_stat, week_type, dat_date){
  
  if(temporal == "daily"){
    meteo <- meteo
    meteo <- meteo %>% rename(dates = date)
  }
  
  if(temporal == "weekly"){
    if(week_type == "epiweek"){
      meteo$wweek <- epiweek(meteo$date)
      meteo$yyear <- epiyear(meteo$date)
    }
    
    if(week_type == "isoweek"){
      meteo$wweek <- isoweek(meteo$date)
      meteo$yyear <- isoyear(meteo$date)
    }  
    
    if(week_type == "another"){
      ddate <- read.csv(dat_date)
      ddate$date <- as.Date(ddate$date)
      meteo <- left_join(meteo, ddate, by = c("date" = "date"))
    }
    
    if(weekly_stat == "mean"){
      meteo %>% 
        dplyr::group_by(x, y, wweek, yyear) %>% 
        summarise(variable = mean(variable), 
                  dates = median(date)) -> meteo
    }
    
    if(weekly_stat == "sum"){
      meteo %>% 
        dplyr::group_by(x, y, wweek, yyear) %>% 
        summarise(variable = sum(variable), 
                  dates = median(date)) -> meteo
    }
  }
  
  if(temporal == "monthly"){
    
    meteo$mmonth <- month(meteo$date)
    meteo$yyear <- year(meteo$date)
    
    if(weekly_stat == "mean"){
      meteo %>% 
        dplyr::group_by(x, y, mmonth, yyear) %>% 
        summarise(variable = mean(variable), 
                  dates = median(date)) -> meteo
    }
    
    if(weekly_stat == "sum"){
      meteo %>% 
        dplyr::group_by(x, y, mmonth, yyear) %>% 
        summarise(variable = sum(variable), 
                  dates = median(date)) -> meteo
    }
  }
  
  if(temporal == "yearly"){
    
    meteo$yyear <- year(meteo$date)
    
    if(weekly_stat == "mean"){
      meteo %>% 
        dplyr::group_by(x, y, yyear) %>% 
        summarise(variable = mean(variable), 
                  dates = median(date)) -> meteo
    }
    
    if(weekly_stat == "sum"){
      meteo %>% 
        dplyr::group_by(x, y, yyear) %>% 
        summarise(variable = sum(variable), 
                  dates = median(date)) -> meteo
    }
    
  }
  return(meteo)
}


# t_0 <- Sys.time()
# meteo <- TemporalStat(temporal = "daily")
# t_1 <- Sys.time()
# t_1 - t_0 # less than a minute for ERA-5, for CHIPRS it takes ~2 minutes


# t_0 <- Sys.time()
# meteo <- TemporalStat(temporal = "weekly", weekly_stat = "mean", week_type = "isoweek")
# t_1 <- Sys.time()
# t_1 - t_0 # less than a minute for ERA-5, for CHIPRS it takes ~2 minutes


dat_date <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/data/LinkTimeDateClean.csv"
t_0 <- Sys.time()
meteo <- TemporalStat(temporal = "weekly", weekly_stat = "mean", week_type = "another", dat_date = dat_date)
t_1 <- Sys.time()
t_1 - t_0 # less than a minute for ERA-5, for CHIPRS it takes ~2 minutes


##
## Create a spatial id
t_0 <- Sys.time()
meteo$space_id <- paste0(meteo$x, meteo$y) %>% as.factor() %>% as.numeric()
t_1 <- Sys.time()
t_1 - t_0 # less than a minute

meteo %>% select(x, y, variable, dates, space_id) -> meteo

# and store
saveRDS(meteo, file = paste0("Output/SummaryTemporal_", metric, "_", stat, ".rds"))

rm(list = ls())
dev.off()
gc()





