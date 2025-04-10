
# Created 05.04.2025

# Bring together

#-------------------------------------------------------------------------------

library(tidyverse)

wd <- "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/"
setwd(paste0(wd, "Output/"))

metric <- c("2m_temperature", "total_precipitation", "2m_dewpoint_temperature", 
            "CHIRPS_rainfall", "relative_humidity", "specific_humidity")

which.files <- 
  lapply(paste0("Popweighted_", metric), function(Z) list.files() %>% startsWith(.,Z)) %>% 
  do.call(cbind, .) %>% 
  apply(., 1, sum) %>% as.logical()


nords <- gsub(".rds", "", list.files()[which.files])

# select admin 1 and admin 2
admin0 <- list.files()[which.files][endsWith(nords, "0")]
admin1 <- list.files()[which.files][endsWith(nords, "1")]
admin2 <- list.files()[which.files][endsWith(nords, "2")]

admin0_files <- lapply(admin0, function(X) readRDS(X))
admin1_files <- lapply(admin1, function(X) readRDS(X))
admin2_files <- lapply(admin2, function(X) readRDS(X))

# I need to change the colnames and bring together
for(i in 1:length(admin0)) admin0_files[[i]] %>% rename(!!rlang::sym(admin0[i]) := variable) -> admin0_files[[i]]
for(i in 1:length(admin1)) admin1_files[[i]] %>% rename(!!rlang::sym(admin1[i]) := variable) -> admin1_files[[i]]
for(i in 1:length(admin2)) admin2_files[[i]] %>% rename(!!rlang::sym(admin2[i]) := variable) -> admin2_files[[i]]

joined0_df <- reduce(admin0_files, left_join, by = c("NAME", "dates"))
joined1_df <- reduce(admin1_files, left_join, by = c("NAME", "dates"))
joined2_df <- reduce(admin2_files, left_join, by = c("NAME", "dates"))

# remove .rds from colnames
colnames(joined0_df)[colnames(joined0_df) %>% endsWith(., ".rds")] <- colnames(joined0_df)[colnames(joined0_df) %>% endsWith(., ".rds")] %>% gsub(".rds", "", .)
colnames(joined1_df)[colnames(joined1_df) %>% endsWith(., ".rds")] <- colnames(joined1_df)[colnames(joined1_df) %>% endsWith(., ".rds")] %>% gsub(".rds", "", .)
colnames(joined2_df)[colnames(joined2_df) %>% endsWith(., ".rds")] <- colnames(joined1_df)[colnames(joined2_df) %>% endsWith(., ".rds")] %>% gsub(".rds", "", .)

# and store results
saveRDS(joined0_df, file = "PopulationWeightedMeteorology_Level0.rds")
saveRDS(joined1_df, file = "PopulationWeightedMeteorology_Level1.rds")
saveRDS(joined2_df, file = "PopulationWeightedMeteorology_Level2.rds")

rm(list = ls())
dev.off()
gc()




##
## Some more checks!!

# tmp <- readRDS("PopulationWeightedMeteorology_Level2.rds")
# dates_seq <- seq(from = as.Date("2017-01-02"), to = as.Date("2024-12-31"), by = "day")
# dates_seq <- c(as.Date("2017-01-01"), dates_seq[seq(from = 1, to = length(dates_seq), by = 7)])
# dates_seq %>% length()
# 
# tmp_chk <- tmp$dates %>% unique() %>% sort()
# dates_seq[!(dates_seq %in% tmp$dates)]
# tmp_chk[!(tmp_chk %in% dates_seq)] # looks fine
# 
# summary(tmp)

