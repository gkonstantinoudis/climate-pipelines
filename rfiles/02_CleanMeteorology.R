
# Created 02.04.2025

# Clean the ERA5 meteorology data in Sri Lanka

#-------------------------------------------------------------------------------

# set wd
wd <- "C:/Users/gkonstan/OneDrive - Imperial College London/ICRF Imperial/Projects/climate-pipelines/"
setwd(file.path(wd, "Output"))

# libraries
library(tidyverse)
library(terra)


# function to retrieve daily statistic
DailyStat <- function(start, stop, datenam, metric, stat, d = d){
  
  if(stat == "mean"){
    d_stat <- cbind(d[,c(1:2)], d[,-c(1:2)][,start:stop] %>% apply(., 1, mean, na.rm = TRUE))
    colnames(d_stat)[3] <- paste(metric, stat, sep = "_")
  }
  
  if(stat == "min"){
    d_stat <- cbind(d[,c(1:2)], d[,-c(1:2)][,start:stop] %>% apply(., 1, min, na.rm = TRUE))
    colnames(d_stat)[3] <- paste(metric, stat, sep = "_")
  }
  
  if(stat == "max"){
    d_stat <- cbind(d[,c(1:2)], d[,-c(1:2)][,start:stop] %>% apply(., 1, max, na.rm = TRUE))
    colnames(d_stat)[3] <- paste(metric, stat, sep = "_")
  }
  
  if(stat == "sum"){
    d_stat <- cbind(d[,c(1:2)], d[,-c(1:2)][,start:stop] %>% apply(., 1, sum, na.rm = TRUE))
    colnames(d_stat)[3] <- paste(metric, stat, sep = "_")
  }
  
  d_stat$date <- datenam
  
  return(d_stat)
}

# function to extract the data
ExtractDailyStat <- function(Z, stat, metric, dailystat = TRUE){
  
  # get the x-y coordinates
  d <- as.data.frame(Z, xy=TRUE)
  d[,-c(1:2)] <- d[,-c(1:2)] - 273.15
  
  hour_tr <- as.POSIXct(sub(".*=", "", colnames(d)[-c(1:2)]) %>% as.numeric(), origin = "1970-01-01")
  hour_tr <- format(hour_tr, format='%Y-%m-%d', tz = "Asia/Colombo")
  
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
    # start = dat[1,3]; stop = dat[1,4]; datenam = dat[1,1]; stat = stat; d = d; metric = metric
    # run the DailyStat across the data
    GetStat <- 
      apply(dat, 1, function(X){
        return(DailyStat(start = X[3], stop = X[4], datenam = X[1], stat = stat, d = d, metric = metric))
        
      } 
      ) 
    
    GetStat <- do.call(rbind, GetStat)
  }else{
    GetStat <- d
  }
  
  return(GetStat)
}


# # define the metric
# metric <- "2m_temperature"
# # # c("2m_temperature", "total_precipitation")
# # define the statistic
# stat <- "max"
# # mean, min, max and sum


metric_loop <- "2m_temperature" 
stat_loop <- c("mean", "min", "max")
i <- j <- 1

for(i in 1:length(metric_loop)){
  for(j in 1:length(stat_loop)){
    
    print(metric_loop[i]); print(stat_loop[j])
    
    # read the files
    files2read <- list.files()[list.files() %>% startsWith(.,metric_loop[i])]
    meteo_extract <- lapply(files2read, terra::rast) 
    
    # run the function
    res <- lapply(meteo_extract, function(Z) ExtractDailyStat(Z = Z, stat = stat_loop[j], metric = metric_loop[i]))
    res <- do.call(rbind, res) 
    
    # Store the result
    saveRDS(res, file = paste0("Summary_", metric_loop[i], "_", stat_loop[j], ".rds"))
  }
}


rm(list = ls())
gc()



