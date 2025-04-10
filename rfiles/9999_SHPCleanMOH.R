

# Created 10.04.2025

# Clean the shp of Sri Lanka

##
## Colombo

shp_string <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/Output/custom_shp/Colombo_PHI/Colombo_PHI/Colombo_GNDs.shp"
shp <- read_sf(shp_string)

shp %>%
  group_by(MOH_N) %>% 
  rename(NAME = MOH_N) %>% 
  summarize(geometry = st_union(geometry)) -> shp

shp <- shp[!is.na(shp$NAME),]

st_write(shp, "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/Output/custom_shp/custom_MOH/ColomboMOH.shp")



##
## Colombo

shp_string <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/Output/custom_shp/Gampaha_Final/Gampaha_Final/Gampaha_GNDs.shp"
shp <- read_sf(shp_string)

shp %>%
  group_by(MOH_N) %>% 
  rename(NAME = MOH_N) %>% 
  summarize(geometry = st_union(geometry)) -> shp

shp <- shp[!is.na(shp$NAME),]

st_write(shp, "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/Output/custom_shp/custom_MOH/GampahaMOH.shp")

