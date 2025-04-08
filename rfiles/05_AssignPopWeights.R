
# Created 02.04.2025

# Combine meteorology with population.

#-------------------------------------------------------------------------------
      
library(tidyverse)
library(FNN)

# set path
path <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka"
setwd(path)

# read population
year <- 2020
pop <- readRDS(paste0("Output/population_", year))

# read meteorology
# define the metric
metric <- "relative_humidity"
# c("2m_temperature", "total_precipitation", "CHIRPS_rainfall", "specific_humidity", "relative_humidity")

# define the statistic
stat <- "mean"
# mean, min, max and sum

meteo <- readRDS(file = paste0("Output/SummaryTemporal_", metric, "_", stat, ".rds"))


# the idea here is that I will find the NN to the coarse space id and sum
meteo_xy <- meteo[,c("x", "y", "space_id")]
meteo_xy <- meteo_xy[!duplicated(meteo_xy$space_id),]


index.nn <- FNN::get.knnx(meteo_xy[,c("x", "y")], pop[, c("x", "y")], k = 1)$nn.index
pop$space_id <- meteo_xy$space_id[index.nn]
pop %>% 
  dplyr::group_by(space_id) %>% 
  dplyr::summarise(pop = sum(lka_ppp_2020)) -> pop_agg

##
## plot it to make sure it is correct:
# meteo_xy <- left_join(meteo_xy, pop_agg)
# meteo_xy$pop_cat <- 
#   cut(
#     meteo_xy$pop, 
#     breaks = stats::quantile(meteo_xy$pop, probs = seq(0, 1, 0.10), na.rm = TRUE), 
#     labels = 1:10
#   ) %>% as.numeric()
#   
# 
# ggplot() + 
#   geom_point(data = meteo_xy, aes(x=x, y=y, col=pop_cat), size = 5) +
#   scale_color_viridis_c()


##
## and bring back to meteorology
meteo <- left_join(meteo, pop_agg, by = c("space_id" = "space_id"))

# and remove NAs
meteo <- meteo[!is.na(meteo$pop),]

## plot it to make sure it is correct:
# meteo %>% 
#   dplyr::filter(dates == "2017-01-04") %>% 
#   ggplot() + 
#   geom_point(aes(x=x, y=y, col=variable), size = 5) +
#   scale_color_viridis_c()
# 
# meteo %>% 
#   group_by(dates) %>% 
#   summarise(var = mean(variable)) %>% 
#   ggplot() + 
#   geom_line(aes(x=dates, y=var))

# and store
saveRDS(meteo, file = paste0("Output/Popweighted_Summary_", metric, "_", stat, ".rds"))

rm(list = ls())
dev.off()
gc()





                   