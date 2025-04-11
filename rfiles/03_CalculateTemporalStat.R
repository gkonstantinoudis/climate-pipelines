
# Created 07.04.2025

# Get temporal statistic based on the outcome data

#-------------------------------------------------------------------------------

library(tidyverse)
library(FNN)

# set path
path <- "C:/Users/gkonstan/OneDrive - Imperial College London/ICRF Imperial/Projects/climate-pipelines/"
setwd(path)



##
## Calculate the temporal stat

# Arguments:
# temporal <- "daily", "weekly", "monthly" and "yearly"
# weekly_stat <- "mean" or "sum"
# week_type <- "epiweek" or "isoweek" or "another"
# if it is another needs to be an excel file with the following structure!
# wweek yyear       date
# 1     1  2000 1999-12-27
# 2     1  2000 1999-12-28
# 3     1  2000 1999-12-29
# 4     1  2000 1999-12-30
# 5     1  2000 1999-12-31
# 6     1  2000 2000-01-01

TemporalStat <- function(meteo, temporal, weekly_stat, week_type, dat_date){
  
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
        dplyr::group_by(x, y, space_id, wweek, yyear) %>% 
        summarise(variable = mean(variable, na.rm = FALSE), 
                  dates = min(date)) -> meteo
    }
    
    if(weekly_stat == "sum"){
      meteo %>% 
        dplyr::group_by(x, y, space_id, wweek, yyear) %>% 
        summarise(variable = sum(variable, na.rm = FALSE), 
                  dates = min(date)) -> meteo
    }
  }
  
  if(temporal == "monthly"){
    
    meteo$mmonth <- month(meteo$date)
    meteo$yyear <- year(meteo$date)
    
    if(weekly_stat == "mean"){
      meteo %>% 
        dplyr::group_by(x, y, space_id, mmonth, yyear) %>% 
        summarise(variable = mean(variable, na.rm = FALSE), 
                  dates = min(date)) -> meteo
    }
    
    if(weekly_stat == "sum"){
      meteo %>% 
        dplyr::group_by(x, y, space_id, mmonth, yyear) %>% 
        summarise(variable = sum(variable, na.rm = FALSE), 
                  dates = min(date)) -> meteo
    }
  }
  
  if(temporal == "yearly"){
    
    meteo$yyear <- year(meteo$date)
    
    if(weekly_stat == "mean"){
      meteo %>% 
        dplyr::group_by(x, y, space_id, yyear) %>% 
        summarise(variable = mean(variable, na.rm = FALSE), 
                  dates = min(date)) -> meteo
    }
    
    if(weekly_stat == "sum"){
      meteo %>% 
        dplyr::group_by(x, y, space_id, yyear) %>% 
        summarise(variable = sum(variable, na.rm = FALSE), 
                  dates = min(date)) -> meteo
    }
    
  }
  return(meteo)
}

##
## Note: The date is the week, month or year start!! 


##
## Read, clean and store the file

# Regardless of this stat, I calculated the mean of the temporal aggregation selected for everything
# For instance: Although I have calculated sum of daily precipitation, this code selected a temporal aggregation, 
# say week, and will calculate the mean weekly of the daily sum precipitation. The code gives you also the option 
# to calculate the sum, but i selected the mean. 


# Arguments
# metric <- c("2m_temperature", "total_precipitation", "CHIRPS_rainfall", "specific_humidity", "relative_humidity")
# stat <- c("mean", "min", "max", "sum")


CalculateTemporalStat <- function(metric, stat, temporal, weekly_stat, week_type, dat_date){
  
  meteo <- readRDS(paste0("Output/Summary_", metric, "_", stat, ".rds"))
  colnames(meteo)[colnames(meteo) %in% paste0(metric, "_", stat)] <- "variable"
  meteo$date <- as.Date(meteo$date)
  
  t_0 <- Sys.time()
  meteo$space_id <- paste0(meteo$x, meteo$y) %>% as.factor() %>% as.numeric()
  t_1 <- Sys.time()
  t_1 - t_0 # less than a minute
  
  meteo$date <- as.Date(meteo$date)
  
  # there might be duplicates due to the time zone. 
  meteo %>% 
    dplyr::group_by(x, y, space_id, date) %>% 
    dplyr::summarise(variable = mean(variable)) %>% 
    ungroup() -> meteo
  
  
  # make sure we have all the dates
  expand.grid(
    space_id = unique(meteo$space_id), 
    date = seq(from = meteo$date %>% min(), 
               to = meteo$date %>% max(), 
               by = "day")
  ) -> griddat
  
  meteo <- left_join(griddat, meteo, by = c("date" = "date", "space_id" = "space_id"))
  
  meteo <- TemporalStat(meteo = meteo, temporal = temporal, weekly_stat = weekly_stat, 
                        week_type = week_type, dat_date = dat_date)
  
  # and store
  saveRDS(meteo, file = paste0("Output/SummaryTemporal_", metric, "_", stat, ".rds"))
  
  return(meteo)
}



##
## Run the function for the different combinations:

dat_date <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/data/LinkTimeDateClean.csv"

t_0 <- Sys.time()
CalculateTemporalStat(metric = "2m_temperature", stat = "mean", temporal = "weekly", 
                      weekly_stat = "mean", week_type = "another", dat_date = dat_date)

CalculateTemporalStat(metric = "2m_temperature", stat = "min", temporal = "weekly", 
                      weekly_stat = "mean", week_type = "another", dat_date = dat_date)

CalculateTemporalStat(metric = "2m_temperature", stat = "max", temporal = "weekly", 
                      weekly_stat = "mean", week_type = "another", dat_date = dat_date)

CalculateTemporalStat(metric = "CHIRPS_rainfall", stat = "sum", temporal = "weekly", 
                      weekly_stat = "mean", week_type = "another", dat_date = dat_date)

CalculateTemporalStat(metric = "specific_humidity", stat = "mean", temporal = "weekly", 
                      weekly_stat = "mean", week_type = "another", dat_date = dat_date)

CalculateTemporalStat(metric = "relative_humidity", stat = "mean", temporal = "weekly", 
                      weekly_stat = "mean", week_type = "another", dat_date = dat_date)
t_1 <- Sys.time()
t_1 - t_0 # ~ 6 minutes


rm(list = ls())
dev.off()
gc()



#####
##### Checks

# Check the SummaryTemporal_

# metric <- "relative_humidity"
# stat <- "mean"
# meteo <- readRDS(paste0("Output/SummaryTemporal_", metric, "_", stat, ".rds"))
# 
# dates_seq <- seq(from = as.Date("2017-01-02"), to = as.Date("2024-12-31"), by = "day")
# dates_seq <- c(as.Date("2017-01-01"), dates_seq[seq(from = 1, to = length(dates_seq), by = 7)])
# dates_seq %>% length()
# 
# tmp_chk <- meteo$dates %>% unique() %>% sort()
# dates_seq[!(dates_seq %in% meteo$dates)]
# tmp_chk[!(tmp_chk %in% dates_seq)] # looks fine
# 
# head(meteo)
# meteo %>% 
#   dplyr::filter(space_id == 1) %>% 
#   ggplot() + 
#   geom_point(aes(x=dates, y = variable))
# 
# meteo %>% 
#   dplyr::filter(dates == "2017-01-05") %>% 
#   ggplot() + 
#   geom_point(aes(x=x, y = y, col = variable), size = 4) + 
#   scale_color_viridis_c() + theme_bw()


