

# Created 02.04.2025

# Download meteorology in Sri Lanka

#-------------------------------------------------------------------------------

# install.packages(c("tidyverse", "ecmwfr", "parallel"))

# set your working directory
wd <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/"
setwd(wd)

# create a folder Output to store the files
dir.create(file.path(wd, "Output"))

library(tidyverse)
library(ecmwfr)
library(parallel)

# myemail <- "g.konstantinoudis@imperial.ac.uk"
# cds.key <- wf_get_key(user = myemail)

# Set up the API and UID
cds.key <- wf_set_key()

##
## You also need to go to the dataset and accept the terms!!
## here: https://cds.climate.copernicus.eu/datasets/reanalysis-era5-land?tab=overview

metric <- "surface_pressure"
# c("2m_temperature", "total_precipitation", "2m_dewpoint_temperature", "surface_pressure")

###
# THIS IS IF YOU WANT TO UPDATE THE FILES WITH NEWER DATA
update = FALSE
newdates <- "2025-03-01/2025-03-31"
# OR IF YOU WANT MORE
# newdates <- c("2025-02-01/2025-02-28", "2025-03-01/2025-03-31")

DownloadMeteorology <- function(X){
  
  request <- list(
    dataset_short_name = "reanalysis-era5-land",
    product_type = "reanalysis",
    format = "netcdf",
    variable = metric,
    date = X, 
    time = c("00:00", "01:00", "02:00", "03:00", "04:00", "05:00", "06:00", "07:00", "08:00", 
             "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", 
             "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"),
    download_format = "unarchived",
    # area is specified as N, W, S, E
    area = c(10, 78, 5, 82),
    target = paste0(metric, sub(pattern = "/", replacement = "_", x=X), ".nc")
  )
  
  if(!file.exists(paste0("Output/", metric,  sub(pattern = "/", replacement = "_", x=X), ".nc"))) {
    file <- wf_request(request = request,
                       transfer = TRUE,
                       path = "Output",
                       time_out = 3600*24,
                       verbose = TRUE)
  }
  
}


if(update == TRUE){
  toloop <-newdates
}else{
  year <- 2017:2024
  months_list <- paste0("-0", 1:9, "-01")
  months_list <- c(months_list, "-10-01", "-11-01", "-12-31")
  
  define_dates <- lapply(year, function(X) paste(X, months_list, sep = "")) 
  
  lapply(define_dates, function(X) data.frame(start = X[-length(X)], end = X[-1])) %>% do.call(rbind,.) -> define_dates
  
  define_dates$start <- as.Date(define_dates$start)
  define_dates$end <- as.Date(define_dates$end)
  
  toloop <- paste(define_dates$start, define_dates$end, sep = "/")
}



# run on parallel

funpar <- function(k) DownloadMeteorology(X = toloop[k])

t_0 <- Sys.time()

# Set up parallel environment
ncores <- 5
# ncores <- detectCores() - 1
k <- 1:length(toloop)
cl_inla <- makeCluster(ncores, methods=FALSE)

# extract packages on parallel environment 
clusterEvalQ(cl_inla, {
  library(ecmwfr)
})

# extract R objects on parallel environment
clusterExport(cl_inla, c("toloop", "DownloadMeteorology", "cds.key", "metric"))

# run the the function in parallel
outpar <- parLapply(cl = cl_inla, k, funpar)

# close parallel environment
stopCluster(cl_inla)
t_1 <- Sys.time()
t_1 - t_0 # 4 hours


rm(list = ls())
gc()




###
###
### SECOND PART OF CODE, RUN IF THE DOWNLOAD LIMITS ARE MET


LIMITS = FALSE

if(LIMITS == TRUE){
  
  ##
  ## There are limits on the number of quotes submitted per time window, so the code needs to run
  # until you have everything. 
  
  ##
  ## I need to change the toloop
  
  wd <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/"
  setwd(file.path(wd, "Output"))
  
  filesDownloaded <- list.files()[list.files() %>% startsWith(.,metric)]
  filesDownloaded
  gsub(pattern = metric, replacement = "", filesDownloaded) %>% 
    gsub(pattern = ".nc", replacement = "", .) %>% 
    gsub(pattern = "_", replacement = "/", .) -> rem
  
  
  toloop2 <- toloop[!(toloop %in% rem)]
  
  
  funpar <- function(k) DownloadMeteorology(X = toloop2[k])
  
  
  setwd(wd) # reset the wd
  
  t_0 <- Sys.time()
  
  # Set up parallel environment
  ncores <- 20
  # ncores <- detectCores() - 1
  k <- 1:length(toloop2)
  cl_inla <- makeCluster(ncores, methods=FALSE)
  
  # extract packages on parallel environment 
  clusterEvalQ(cl_inla, {
    library(ecmwfr)
  })
  
  # extract R objects on parallel environment
  clusterExport(cl_inla, c("toloop2", "DownloadMeteorology", "cds.key", "metric"))
  
  # run the the function in parallel
  outpar <- parLapply(cl = cl_inla, k, funpar)
  
  # close parallel environment
  stopCluster(cl_inla)
  t_1 <- Sys.time()
  t_1 - t_0 
  
}


rm(list = ls())
gc()



