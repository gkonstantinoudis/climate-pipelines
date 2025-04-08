
# Created 07.04.2025

# Quality checks

#-------------------------------------------------------------------------------

library(tidyverse)


wd <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/"
setwd(paste0(wd, "Output/"))

dat_me <- readRDS(file = "PopulationWeightedMeteorology_Level1.rds")
dat_sally <- readRDS("C:/Users/gkonstan/OneDrive - Imperial College London/dektop/pres/datfin3.rds")


# select a municipality
dat_sally$area[1]

nam <- "Ampara"


dat_me %>% filter(NAME %in% "Ampara") %>% pull(Popweighted_2m_temperature_max_level_1)
dat_me %>% filter(NAME %in% "Ampara") %>% View()
dat_sally %>% filter(area %in% "Ampara") %>% View()

dat_sally$week %>% class()
dat_sally$end_week %>% class()
dat_sally$mid_date <- dat_sally$week + as.numeric(difftime(dat_sally$end_week, dat_sally$week, units = "days")) / 2

ggplot() + 
  geom_point(data = dat_me %>% filter(NAME %in% "Ampara"), aes(x=dates, y=`Popweighted_2m_temperature_max_level_1`)) + 
  geom_point(data = dat_sally %>% 
               filter(area %in% "Ampara"), 
             aes(x=mid_date, y=temperature.max), col = "red", alpha = 0.5)


dat_me$Popweighted_2m_temperature_max_level_1 %>% pull(Popweighted_2m_temperature_max_level_1)
rm(list = ls())
dev.off()
gc()


dat_me$NAME %>% unique() %>% length()
dat_me$dates %>% unique() %>% length()

dat_sally$area %>% unique() %>% length()
dat_sally$week %>% unique() %>% length()
