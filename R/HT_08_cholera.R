# Haiti DHS Activity Design -----------------------------------------
#
# HT_08_cholera.R: Plot hot spots of cholera activity
#
# Script to pull data from the Demographic and Health Surveys on variables
# related to water, sanitation, and hygiene (WASH)
# 
# Data are from UNICEF's classification of prevalence of cholera
#
# Laura Hughes, lhughes@usaid.gov, 15 August 2016
# With Patrick Gault (pgault@usaid.gov) and Tim Essam (tessam@usaid.gov)
#
# Copyright 2016 by Laura Hughes via MIT License
#
# -------------------------------------------------------------------------

# Previous dependencies ---------------------------------------------------
# `HT_01_importDHS_geo.R` are meant to be run first.  The following are dependencies in thoses files:

# * admin0-2, etc.: shapefiles containing geographic polygons of Haiti + basemaps
# * libraries


# Set colors and other basics ---------------------------------------------
colour_cholera = 'YlGn'


# Import data -------------------------------------------------------------

# List of priority communes for cholera interventions, as identified by UNICEF
# Raw data file cleaned up to match commune names by hand; in separate column ('commune' instead of 'communes')
cholera = read_excel('~/Documents/USAID/Haiti/rawdata/Haiti_cholera_UNICEF/Cholera Response Commune and Total Sanitation Campaign August 2016.xlsx', 
                     sheet = 2, skip = 1)


# List of cholera hotspot cities, where infections tend to occur.
chol_cities = read_csv('~/Documents/USAID/Haiti/rawdata/Haiti_cholera_UNICEF/Haiti_cholera_hotspotcities_UNICEF_2016-08-29.csv')



# Clean data --------------------------------------------------------------

cholera = cholera %>% 
  # Remove blank / rows or ones w/ coded data.
  filter(!is.na(Priority)) %>% 
  # Encode Category based on 2016 UNICEF classification
  mutate(prevalence2016 = factor(`Cholera Response (Mid-term Plan)`, 
                             levels = c('C', 'B' ,'A'),
                             labels = c('third priority', 'second priority', 'first priority')),
         prevalence2014 = ifelse(Priority == 'Phase 1', 2,
                                 ifelse(Priority == 'Phase 2', 1, NA)),
         commune = str_trim(commune),
         departement = str_trim(`Departement `))

# Merge City with Haiti
chol_cities = chol_cities %>% mutate(loc = paste0(city, ', Haiti'))

# Geocode cholera cities --------------------------------------------------
chol_cities = geocode(chol_cities$loc, messaging = TRUE, output = 'more')

# Visually check they're okay

info_popup <- paste0("<strong>Dep.: </strong>", 
                             chol_cities$administrative_area_level_1,
                             "<br><strong>city: </strong> <br>",
                             chol_cities$address)

leaflet(chol_cities) %>% 
  addCircles(~lon, ~lat, radius = 4000, opacity =  1,
             color = ~paired(administrative_area_level_1),
             popup = info_popup) %>% 
  addProviderTiles("Thunderforest.Landscape")

# Merge commune-level data with maps --------------------------------------
cholera_map = left_join(cholera, admin3$df, by = c('commune', 'departement'))


# Cholera prevalence map --------------------------------------------------

plotMap(cholera_map, 
        fill_var = 'prevalence2014',
        fill_scale = colour_cholera,
        fill_limits = c(0.5, 3.5))