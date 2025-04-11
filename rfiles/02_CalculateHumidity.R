

# Created 04.04.2025

# Script to calculate humidity 

#-------------------------------------------------------------------------------


# set wd
wd <- "C:/Users/gkonstan/OneDrive - Imperial College London/ICRF Imperial/Projects/climate-pipelines/"
setwd(file.path(wd, "Output"))

# libraries
library(tidyverse)
library(terra)


# function to retrieve daily statistic
DailyStat <- function(start, stop, datenam, metric, d = d){
  
  d_stat <- cbind(d[,c(1:2)], d[,-c(1:2)][,start:stop] %>% apply(., 1, mean))
  colnames(d_stat)[3] <- metric
  
  d_stat$date <- datenam
  
  return(d_stat)
}

# extract the data
Extract <- function(Z, Cel = FALSE){
  
  d <- as.data.frame(Z, xy=TRUE)
  
  if(Cel == TRUE){
    d[,-c(1:2)] <- d[,-c(1:2)] - 273.15
  }else{
    d <- d
  }
  
  hour_tr <- terra::time(Z)
  hour_tr <- format(hour_tr, format='%Y-%m-%d', tz = "Asia/Colombo")
  colnames(d)[-c(1:2)] <- hour_tr
  
  return(d)
}


##
# Temperature
# read the files for temperature
files2read <- list.files()[list.files() %>% startsWith(.,"2m_temperature")]
meteo_extract <- lapply(files2read, terra::rast) 

t_0 <- Sys.time()
res_temperature <- lapply(meteo_extract, function(Z) Extract(Z = Z, Cel = TRUE))
t_1 <- Sys.time()
t_1 - t_0 # less than a minute




##
# Temperature dew point
# read the files for temperature dew point
files2read <- list.files()[list.files() %>% startsWith(.,"2m_dewpoint_temperature")]
meteo_extract <- lapply(files2read, terra::rast) 

t_0 <- Sys.time()
res_temperatureDP <- lapply(meteo_extract, function(Z) Extract(Z = Z, Cel = TRUE))
t_1 <- Sys.time()
t_1 - t_0 # less than a minute





##
# Pressure
# read the files for surface pressure
files2read <- list.files()[list.files() %>% startsWith(.,"surface_pressure")]
meteo_extract <- lapply(files2read, terra::rast) 

t_0 <- Sys.time()
res_pressure <- lapply(meteo_extract, function(Z) Extract(Z = Z))
t_1 <- Sys.time()
t_1 - t_0 # less than a minute



# the function to transform
vp <- function(X){
  6.112*exp(17.67*X/(X + 243.5)) %>% return()
}


rh <- list()
sh <- list()

for(i in 1:length(res_temperature)){
  eD <- vp(res_temperatureDP[[i]])
  eT <- vp(res_temperature[[i]])
  sp <- res_pressure[[i]]
    
  rh[[i]] <- 100*eD/eT
  rh[[i]]$x <- res_temperatureDP[[i]]$x
  rh[[i]]$y <- res_temperatureDP[[i]]$y
  
  sh[[i]] <- 0.622*eD/(sp - 0.378*eD)
  sh[[i]]$x <- res_temperatureDP[[i]]$x
  sh[[i]]$y <- res_temperatureDP[[i]]$y
}
  

##
## This function takes values j = 1:length(rh) or sh. That means that it calculates
## the mean value for every file downloaded. To be correct the files downloaded should be
## compatible with days and not split. 

CalculateDailyStat <- function(j, metric, list_hum){
  
  d <- list_hum[[j]]
  chk <- colnames(d)[-c(1:2)]
  dat <- as.data.frame(table(chk))
  
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
      return(DailyStat(start = X[3], stop = X[4], datenam = X[1], d = d, metric = metric))
    } 
    ) 
  
  do.call(rbind, GetStat) %>% return()
}


##
# Retrieve daily mean relative humidity
t_0 <- Sys.time()
rh_list <- lapply(1:length(rh), function(Z) CalculateDailyStat(j = Z, metric = "rh", list_hum = rh))
rh_res <- do.call(rbind, rh_list)
t_1 <- Sys.time()
t_1 - t_0 # less than a minute

colnames(rh_res)[3] <- "variable"
head(rh_res)

# and store
stat <- "mean"
metric <- "relative_humidity"
saveRDS(rh_res, file = paste0("Summary_", metric, "_", stat, ".rds"))


##
# Retrieve daily mean specific humidity
t_0 <- Sys.time()
sh_list <- lapply(1:length(sh), function(Z) CalculateDailyStat(j = Z, metric = "sh", list_hum = sh))
sh_res <- do.call(rbind, sh_list)
t_1 <- Sys.time()
t_1 - t_0 # less than a minute

colnames(sh_res)[3] <- "variable"
head(sh_res)

# and store
stat <- "mean"
metric <- "specific_humidity"
saveRDS(sh_res, file = paste0("Summary_", metric, "_", stat, ".rds"))


rm(list = ls())
dev.off()
gc()
