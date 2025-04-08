
# Created 04.04.2025

# Aggregate on shapefile

#-------------------------------------------------------------------------------
      
library(tidyverse)
library(sf)
library(FNN)

# set path
path <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka"
setwd(path)



###
## Locate the main .shp file
# If you have your own shapefile define the path in the shp_string object, if not, 
# follow the lines:

shp_file <- list.files(paste0(path, "/Output/"), pattern = "\\.shp$", full.names = TRUE)

########
########
# You need to define which level you are interested in
level <- 2
shp_string <- shp_file[str_sub(gsub(".shp", "", shp_file), -1) == level]

shp <- read_sf(shp_string)

shp$NAME <- shp %>% pull(paste0("NAME_", level))

###
## read meteorology with population weights
# define the metric
metric <- "relative_humidity"
# c("2m_temperature", "total_precipitation", "CHIRPS_rainfall", "specific_humidity", "relative_humidity")

# define the statistic
stat <- "mean"
# mean, min, max and sum

meteo <- readRDS(paste0("Output/Popweighted_Summary_", metric, "_", stat, ".rds"))



###
## I need to see where the x and y fall. This ensures that if the polygons contain more than
## two points, you take the average with population weights.

dat_points <- meteo[!duplicated(meteo$space_id),]
dat_points <- dat_points[,c("x", "y", "space_id")]

# plot(shp$geometry)
# points(dat_points$x, dat_points$y, col = "red")

# Convert points to an sf object
points_sf <- st_as_sf(dat_points, coords = c("x", "y"), crs = st_crs(shp))
# and st_join them
point_in_polygon <- st_join(points_sf, shp, join = st_within)

# need to select the name of the level
dat_points$NAME <- point_in_polygon %>% 
  pull(paste0("NAME_", level))
dat_points_tmp <- dat_points

dat_points_tmp <- dat_points_tmp[!is.na(dat_points_tmp$NAME),]

# if TRUE there are no NAs. 
# If its FALSE, there are NAs, we need to do more!!
(unique(dat_points_tmp$NAME) %>% length()) == nrow(shp)


# bring back to meteo
meteo_tmp <- left_join(meteo, dat_points_tmp[,c("space_id", "NAME")], by = c("space_id" = "space_id"))
summary(meteo_tmp)

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
(meteo_weighted$dates %>% unique() %>% length())*(meteo_weighted$NAME %>% unique() %>% length()) == nrow(meteo_weighted)


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
(meteo_weighted$NAME %>% unique() %>% length()) == (nrow(shp))
(meteo$dates %>% unique() %>% length())*(nrow(shp)) == nrow(meteo_weighted)

##
## and some plots

# time
ggplot() + 
  geom_line(data = meteo_weighted, aes(x = dates, y = variable, col = NAME), alpha = 0.5) + 
  theme(legend.position = "none")

# space
meteo_weighted %>% 
  filter(dates == "2017-01-01") %>% 
  left_join(shp, meteo_weighted, by = c("NAME" = "NAME")) %>% 
  st_as_sf() %>% 
  ggplot() + 
  geom_sf(aes(fill = variable), col = NA) + 
  scale_fill_viridis_c() +
  theme_bw()



saveRDS(meteo_weighted, file = paste0("Output/Popweighted_", metric, "_", stat, "_level_",  level, ".rds"))


rm(list = ls())
dev.off()
gc()



                   