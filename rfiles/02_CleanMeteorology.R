
# Created 02.04.2025

# Clean the ERA5 meteorology data in Sri Lanka

#-------------------------------------------------------------------------------

# set wd
wd <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/"
setwd(file.path(wd, "Output"))

# libraries
library(tidyverse)
library(terra)

# define the metric
metric <- "2m_dewpoint_temperature"
# # c("2m_temperature", "total_precipitation", "2m_dewpoint_temperature")

# define the statistic
stat <- "mean"
# mean, min, max and sum

# function to retrieve daily statistic
DailyStat <- function(start, stop, datenam, metric, stat, d = d){
  
  if(stat == "mean"){
    d_stat <- cbind(d[,c(1:2)], d[,-c(1:2)][,start:stop] %>% apply(., 1, mean))
    colnames(d_stat)[3] <- paste(metric, stat, sep = "_")
  }
  
  if(stat == "min"){
    d_stat <- cbind(d[,c(1:2)], d[,-c(1:2)][,start:stop] %>% apply(., 1, min))
    colnames(d_stat)[3] <- paste(metric, stat, sep = "_")
  }
  
  if(stat == "max"){
    d_stat <- cbind(d[,c(1:2)], d[,-c(1:2)][,start:stop] %>% apply(., 1, max))
    colnames(d_stat)[3] <- paste(metric, stat, sep = "_")
  }
  
  if(stat == "sum"){
    d_stat <- cbind(d[,c(1:2)], d[,-c(1:2)][,start:stop] %>% apply(., 1, sum))
    colnames(d_stat)[3] <- paste(metric, stat, sep = "_")
  }
  
  d_stat$date <- datenam
  
  return(d_stat)
}


# read the files
files2read <- list.files()[list.files() %>% startsWith(.,metric)]
meteo_extract <- lapply(files2read, terra::rast) 


# extract the data
ExtractDailyStat <- function(Z, stat, dailystat = TRUE){
  
  d <- as.data.frame(Z, xy=TRUE)
  d[,-c(1:2)] <- d[,-c(1:2)] - 273.15
  
  hour_tr <- terra::time(Z)
  hour_tr <- format(hour_tr, format='%Y-%m-%d', tz = "Asia/Colombo")
  TakeMonth <- month(hour_tr) == month(hour_tr)[1]
  hour_tr <- hour_tr[TakeMonth]
  
  d <- cbind(d[,c(1:2)], d[,-c(1:2)][,TakeMonth])
  colnames(d)[-c(1:2)] <- hour_tr[TakeMonth]
  
  if(dailystat == TRUE){
    # define the start/end points of each date
    dat <- as.data.frame(table(hour_tr))
    
    start <- numeric(nrow(dat))
    stop <- numeric(nrow(dat))
    
    start[1] <- 1
    stop[1] <- dat$Freq[1]
    
    
    for(i in 2:nrow(dat)){
      start[i] <- stop[i-1] + 1
      stop[i] <- start[i] + dat$Freq[i] - 1
    }
    
    dat$start <- start
    dat$stop <- stop
    
    # run the DailyStat across the data
    GetStat <- 
      apply(dat, 1, function(X){
        return(DailyStat(start = X[3], stop = X[4], datenam = X[1], stat = stat, d = d, metric = metric))
        
      } 
      ) 
    
    GetStat <- do.call(rbind, GetStat)
  }
  
  GetStat <- d
  return(GetStat)
}


t_0 <- Sys.time()
res <- lapply(meteo_extract, function(Z) ExtractDailyStat(Z = Z, stat = stat))
t_1 <- Sys.time()
t_1 - t_0 # less than a minute
res <- do.call(rbind, res) 


##
## Store the result
saveRDS(res, file = paste0("Summary_", metric, "_", stat, ".rds"))


rm(list = ls())
gc()







