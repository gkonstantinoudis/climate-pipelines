
# Created 04.04.2025

# Download NUTS3 regions

#-------------------------------------------------------------------------------

install.packages("giscoR")
library(giscoR)

# Download NUTS 3 for France

greece_nuts3 <- gisco_get_nuts(year = 2021, nuts_level = 3, country = "EL", resolution = "03")
france_nuts3 <- gisco_get_nuts(year = 2021, nuts_level = 3, country = "FR", resolution = "03")
italy_nuts3 <- gisco_get_nuts(year = 2021, nuts_level = 3, country = "IT", resolution = "03")
spain_nuts3 <- gisco_get_nuts(year = 2021, nuts_level = 3, country = "ES", resolution = "03")


