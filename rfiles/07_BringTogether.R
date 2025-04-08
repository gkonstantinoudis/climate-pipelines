
# Created 05.04.2025

# Bring together

#-------------------------------------------------------------------------------

library(tidyverse)

wd <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/"
setwd(paste0(wd, "Output/"))

metric <- c("2m_temperature", "total_precipitation", "2m_dewpoint_temperature", "CHIRPS_rainfall", "relative_humidity", "specific_humidity")

which.files <- 
  lapply(paste0("Popweighted_", metric), function(Z) list.files() %>% startsWith(.,Z)) %>% 
  do.call(cbind, .) %>% 
  apply(., 1, sum) %>% as.logical()


nords <- gsub(".rds", "", list.files()[which.files])

# select admin 1 and admin 2
admin1 <- list.files()[which.files][endsWith(nords, "1")]
admin2 <- list.files()[which.files][endsWith(nords, "2")]

admin1_files <- lapply(admin1, function(X) readRDS(X))
admin2_files <- lapply(admin2, function(X) readRDS(X))

# I need to change the colnames and bring together
for(i in 1:length(admin1)) admin1_files[[i]] %>% rename(!!rlang::sym(admin1[i]) := variable) -> admin1_files[[i]]
for(i in 1:length(admin2)) admin2_files[[i]] %>% rename(!!rlang::sym(admin2[i]) := variable) -> admin2_files[[i]]

joined1_df <- reduce(admin1_files, left_join, by = c("NAME", "dates"))
joined2_df <- reduce(admin2_files, left_join, by = c("NAME", "dates"))

# remove .rds from colnames
colnames(joined1_df)[colnames(joined1_df) %>% endsWith(., ".rds")] <- colnames(joined1_df)[colnames(joined1_df) %>% endsWith(., ".rds")] %>% gsub(".rds", "", .)
colnames(joined2_df)[colnames(joined2_df) %>% endsWith(., ".rds")] <- colnames(joined1_df)[colnames(joined2_df) %>% endsWith(., ".rds")] %>% gsub(".rds", "", .)

# and store results
saveRDS(joined1_df, file = "PopulationWeightedMeteorology_Level1.rds")
saveRDS(joined2_df, file = "PopulationWeightedMeteorology_Level2.rds")

rm(list = ls())
dev.off()
gc()

