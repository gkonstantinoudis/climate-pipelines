
# Created 04.04.2025

# Aggregate on shapefile

#-------------------------------------------------------------------------------
      
library(tidyverse)
library(sf)
library(FNN)
library(patchwork)

# set path
path <- "C:/Users/gkonstan/OneDrive - Imperial College London/ICRF Imperial/Projects/climate-pipelines/"
setwd(path)


##
## Function 

# Arguments
# metric <- c("2m_temperature", "total_precipitation", "CHIRPS_rainfall", "specific_humidity", "relative_humidity")
# stat <- c("mean", "min", "max", "sum")
# level <- c(0, 1, 2)
# shp_string = NULL, if you have your own shapefile define the path in the shp_string object
# plot = F, if TRUE it will return a plot check

SHP_aggregation <- function(metric, stat, level, shp_string = NULL, plot = F, store = T){
  
  # Meteo file
  meteo <- readRDS(paste0("Output/Popweighted_Summary_", metric, "_", stat, ".rds"))
  
  # .shp file
  
  if(is.null(shp_string)){
    
    shp_file <- list.files(paste0(path, "/Output/"), pattern = "\\.shp$", full.names = TRUE)
    level <- level
    shp_string <- shp_file[str_sub(gsub(".shp", "", shp_file), -1) == level]
    
  }
  
  # read the shp
  sf_use_s2(TRUE)
  shp <- read_sf(shp_string)
  
  if(level == 0){
    shp$NAME <- shp %>% pull(paste0("GID_0"))
  }
  
  if(level == 1 | level == 2){
    shp$NAME <- shp %>% pull(paste0("NAME_", level))
  }
  
  if(!(level %in% 0:2)){
    sf::sf_use_s2(FALSE)
    shp <- st_transform(shp, crs = 4326)
  }
  
  shp <- shp[complete.cases(shp$NAME),]
  
  ###
  ## I need to see where the x and y fall. This ensures that if the polygons contain more than
  ## two points, you take the average with population weights.
  
  dat_points <- meteo[!duplicated(meteo$space_id),]
  dat_points <- dat_points[,c("x", "y", "space_id")]
  
  # Convert points to an sf object
  points_sf <- st_as_sf(dat_points, coords = c("x", "y"), crs = st_crs(shp))
  # and st_join them
  point_in_polygon <- st_join(points_sf, shp, join = st_within)
  
  # need to select the name of the level
  dat_points$NAME <- point_in_polygon %>% 
    pull(NAME)
  dat_points_tmp <- dat_points
  
  dat_points_tmp <- dat_points_tmp[!is.na(dat_points_tmp$NAME),]
  
  # if TRUE there are no NAs. 
  # If its FALSE, there are NAs, we need to do more!!
  print("First check: If false there are regions without meteorological estimates")
  print((unique(dat_points_tmp$NAME) %>% length()) == nrow(shp))
  
  
  # bring back to meteo
  meteo_tmp <- left_join(meteo, dat_points_tmp[,c("space_id", "NAME")], by = c("space_id" = "space_id"))
  
  
  # The NAs here could be the ones out of the shp
  meteo_tmp <- meteo_tmp[!is.na(meteo_tmp$NAME),]
  
  # and aggregate per shp
  meteo_tmp %>% 
    dplyr::group_by(NAME, dates) %>% 
    dplyr::summarise(
      variable = sum(variable*pop)/sum(pop)
    ) -> meteo_weighted
  
  
  ##
  ## THIS NEEDS TO BE TRUE!! (CHECK)
  print("Second check: needs to be TRUE")
  print(
    (meteo_weighted$dates %>% unique() %>% length())*(meteo_weighted$NAME %>% unique() %>% length()) == nrow(meteo_weighted)
  )
  
  ##
  ## This is when the areas are v small and there is no point falling. In this case, 
  ## we will get the first NN. 
  
  
  if((unique(dat_points_tmp$NAME) %>% length()) != nrow(shp)){
    
    # I first need to identify the areas with missing values
    missing_areas <- shp$NAME[!(shp$NAME %in% unique(dat_points$NAME))]
    
    # I need to find the NN of the areas that have missing values
    shp_missing <- shp[shp$NAME %in% missing_areas,]
    points_missing <- shp_missing %>% st_centroid() %>% st_coordinates()
    index.nn.missing <- get.knnx(data = dat_points[c("x", "y")], query = points_missing, k = 1)$nn.index
    shp_missing$id_space <- dat_points$space_id[index.nn.missing]
    
    # expand the grid of all the dates and the missing names
    grid.values <- expand.grid(dates = meteo_weighted$dates %>% unique(), 
                               NAME = shp_missing$NAME %>% unique())
    
    shp_missing <- shp_missing %>% select(id_space, NAME)
    shp_missing$geometry <- NULL
    
    # bring the grid together with the shp
    grid.values <- left_join(grid.values, shp_missing, by = c("NAME" = "NAME"))
    # get the temperature
    grid.values <- left_join(grid.values, meteo, by = c("dates" = "dates", "id_space" = "space_id"))
    # make it identical with the meteo_weighted
    grid.values %>% select(NAME, dates, variable) -> grid.values
    # bring back to the meteo_weighted
    meteo_weighted <- rbind(meteo_weighted, grid.values)
    
  }
  
  
  ##
  ## some checks:
  ## BOTH OF THEM NEED TO BE TRUE
  print("Third check: need to be TRUE")
  print((meteo_weighted$NAME %>% unique() %>% length()) == (nrow(shp)))
  print((meteo$dates %>% unique() %>% length())*(nrow(shp)) == nrow(meteo_weighted))
  
  ##
  ## and some plots
  
  if(plot == TRUE){
    
    print(
      # time
      (ggplot() + 
         geom_line(data = meteo_weighted, aes(x = dates, y = variable, group = NAME, col = NAME), alpha = 0.5) + 
         theme(legend.position = "none"))| 
        
        # space
        (meteo_weighted %>% 
           filter(dates == "2017-01-01") %>% 
           left_join(shp, meteo_weighted, by = c("NAME" = "NAME")) %>% 
           st_as_sf() %>% 
           ggplot() + 
           geom_sf(aes(fill = variable), col = NA) + 
           scale_fill_viridis_c() +
           theme_bw())
    )
    
  }
  
  if(store == TRUE){
    saveRDS(meteo_weighted, file = paste0("Output/Popweighted_", metric, "_", stat, "_level_",  level, ".rds"))
  }
  
  return(meteo_weighted)
}




##
## If you put you custom shp it needs to have a column "NAME" that will be used for the aggregation.

# Run the function for the different datasets and levels

t_0 <- Sys.time()
# Temperature
SHP_aggregation(metric = "2m_temperature", stat = "mean", level = 0, plot = T)
SHP_aggregation(metric = "2m_temperature", stat = "mean", level = 1, plot = T)
SHP_aggregation(metric = "2m_temperature", stat = "mean", level = 2, plot = T)

SHP_aggregation(metric = "2m_temperature", stat = "min", level = 0, plot = T)
SHP_aggregation(metric = "2m_temperature", stat = "min", level = 1, plot = T)
SHP_aggregation(metric = "2m_temperature", stat = "min", level = 2, plot = T)

SHP_aggregation(metric = "2m_temperature", stat = "max", level = 0, plot = T)
SHP_aggregation(metric = "2m_temperature", stat = "max", level = 1, plot = T)
SHP_aggregation(metric = "2m_temperature", stat = "max", level = 2, plot = T)

# Rainfall
SHP_aggregation(metric = "CHIRPS_rainfall", stat = "sum", level = 0, plot = T)
SHP_aggregation(metric = "CHIRPS_rainfall", stat = "sum", level = 1, plot = T)
SHP_aggregation(metric = "CHIRPS_rainfall", stat = "sum", level = 2, plot = T)

# Humidity
SHP_aggregation(metric = "specific_humidity", stat = "mean", level = 0, plot = T)
SHP_aggregation(metric = "specific_humidity", stat = "mean", level = 1, plot = T)
SHP_aggregation(metric = "specific_humidity", stat = "mean", level = 2, plot = T)

SHP_aggregation(metric = "relative_humidity", stat = "mean", level = 0, plot = T)
SHP_aggregation(metric = "relative_humidity", stat = "mean", level = 1, plot = T)
SHP_aggregation(metric = "relative_humidity", stat = "mean", level = 2, plot = T)
t_1 <- Sys.time()
t_1 - t_0 # ~ 1 minute



rm(list = ls())
dev.off()
gc()




##
## Run some additional checks
# metric = "CHIRPS_rainfall"; stat = "sum"; level = 1
# tmp <- readRDS(paste0("Output/Popweighted_", metric, "_", stat, "_level_",  level, ".rds"))
# 
# dates_seq <- seq(from = as.Date("2017-01-02"), to = as.Date("2024-12-31"), by = "day")
# dates_seq <- c(as.Date("2017-01-01"), dates_seq[seq(from = 1, to = length(dates_seq), by = 7)])
# dates_seq %>% length()
# 
# tmp_chk <- tmp$dates %>% unique() %>% sort()
# dates_seq[!(dates_seq %in% tmp$dates)]
# tmp_chk[!(tmp_chk %in% dates_seq)] # looks fine
# 
# summary(tmp)

