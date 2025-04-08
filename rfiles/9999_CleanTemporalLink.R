
# Created 07.04.2025

# Clean the link file

#-------------------------------------------------------------------------------

library(dplyr)
library(tidyr)
library(purrr)
library(lubridate)

df <- read.csv("C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/data/LinkTimeDate.csv")

df <- df %>%
  mutate(
    WeekStart = dmy(WeekStart),
    WeekEnd = dmy(WeekEnd)
  )

# 3. Expand each row to daily dates
df_long <- df %>%
  mutate(DateSeq = map2(WeekStart, WeekEnd, ~ {
    if (!is.na(.x) & !is.na(.y)) {
      seq(.x, .y, by = "day")
    } else {
      NA
    }
  })) %>%
  unnest(DateSeq) %>%
  rename(Date = DateSeq) %>%
  filter(!is.na(Date))



df_long$wweek <- df_long$Week
df_long$yyear <- df_long$Year


df_long %>% 
  select(wweek, yyear, date=Date) -> df_long

  
write.csv(df_long, file = "C:/Users/gkonstan/OneDrive - Imperial College London/meteo_sri_lanka/data/LinkTimeDateClean.csv", row.names = FALSE)

