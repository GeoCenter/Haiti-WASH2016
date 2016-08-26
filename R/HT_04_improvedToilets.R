# Haiti DHS Activity Design -----------------------------------------
#
# HT_04_improvedToilets: calculate improved latrine percentages
#
# Script to pull data from the Demographic and Health Surveys on variables
# related to water, sanitation, and hygiene (WASH)
# 
# Data are from the 2012 DHS, available at http://dhsprogram.com/what-we-do/survey/survey-display-368.cfm
#
# Laura Hughes, lhughes@usaid.gov, 15 August 2016
# With Patrick Gault (pgault@usaid.gov) and Tim Essam (tessam@usaid.gov)
#
# Copyright 2016 by Laura Hughes via MIT License
#
# -------------------------------------------------------------------------

# Previous dependencies ---------------------------------------------------
# `HT_01_importDHS_geo.R`, `HT_02_importDHS_hh.R` are meant to be run first.  The following are dependencies in thoses files:

# * hh: dataframe with household-level indicators
# * admin1-3: shapefiles containing geographic polygons of Haiti
# * DHSdesign: survey object containing the 

# classify improved/ not improved -----------------------------------------
# DHS claims to use WHO definitions for sanitation; similar to those provided by Dr. Elizabeth Jordan, 
# WHO/UNICEF Joint Monitoring Programme for Water Supply and Sanitation: http://www.wssinfo.org/definitions-methods/watsan-categories/

# -- TOILETS --
# export types of toilets in survey
toilet_types = attr(hh_raw$hv205, 'labels')
write.csv(toilet_types, '~/GitHub/Haiti-WASH2016/dataout/DHS_toilet_types.csv')

# read in Liz Jordan's classification of whether or not a toilet or water source is improved (see below in comments)
toilet_types = read.csv('~/GitHub/Haiti-WASH2016/dataout/DHS_toilet_classification.csv')
impr_toilet_codes = unlist(toilet_types %>% filter(improved == 'Improved') %>% select(code))
unimpr_toilet_codes = unlist(toilet_types %>% filter(improved == 'Unimproved') %>% select(code))
od_codes =  unlist(toilet_types %>% filter(improved == 'open defecation') %>% select(code))

# Toilets are defined as being 'improved' if they are one of the following types and aren't shared.
# Note: DHS defines mobile chemical toilets as improved (presumably b/c they treat the waste)
# Only 13 hh outside the camps use them.  Using Liz's definitions (against DHS)

# -- Improved sanitation definitions --
#                           toilet_type code        improved
#                         flush toilet   10        Improved
#          flush to piped sewer system   11        Improved
#                 flush to septic tank   12        Improved
#                 flush to pit latrine   13        Improved
#              flush to somewhere else   14        Improved
#              flush, don't know where   15        Improved
#                   pit toilet latrine   20        Improved
# ventilated improved pit latrine (vip)   21        Improved
#                pit latrine with slab   22        Improved
#                    composting toilet   41        Improved
#                          no facility   30 open defecation
#               no facility/bush/field   31 open defecation
#    pit latrine without slab/open pit   23      Unimproved
#                        bucket toilet   42      Unimproved
#               hanging toilet/latrine   43      Unimproved
#           toilet hanging (on stilts)   44      Unimproved
#               mobile chemical toilet   45      Unimproved
#                                other   96      Unimproved


# Checking that DHS variable "share_toilet" is correct binary for whether only one household uses toilet:
# hh %>% group_by(share_toilet, num_share_toilet) %>% summarise(n())

# -- Reclassify toilets as being improved or not. --
hh = hh %>% 
  mutate(
    # -- straight classification of whether the source is improved --
    toilet_type = case_when(hh$toilet_source %in% impr_toilet_codes ~ 'improved',
                            hh$toilet_source %in% unimpr_toilet_codes ~ 'unimproved',
                            hh$toilet_source %in% od_codes ~ 'open defecation',
                            TRUE ~ NA_character_))

hh = hh %>% 
  mutate(
    # -- improved source + unshared --
    improved_toilet = case_when(is.na(hh$toilet_type) ~ NA_real_,
                                (hh$toilet_type == 'improved' & hh$share_toilet == 0) ~ 1, # improved, unshared
                                (hh$toilet_type == 'improved' & hh$share_toilet == 1) ~ 0, # improved, shared
                                hh$toilet_type %in% c('unimproved', 'open defecation') ~ 0, # unimproved or open defecation
                                TRUE ~ NA_real_),
    impr_toilet_type = case_when(is.na(hh$toilet_type) ~ NA_character_,
                                 (hh$toilet_type == 'improved' & hh$share_toilet == 0) ~ 'improved-unshared', # improved, unshared
                                 (hh$toilet_type == 'improved' & hh$share_toilet == 1) ~ 'improved-shared', # improved, shared
                                 hh$toilet_type == 'unimproved' ~ 'unimproved', # unimproved
                                 hh$toilet_type == 'open defecation' ~ 'open defecation', # open defecation
                                 TRUE ~ NA_character_)
  )


# -- Quick summary tables --
hh %>% group_by(toilet_type, improved_toilet) %>% summarise(n = n()) %>% ungroup() %>% mutate(pct = percent(n/sum(n), ndigits = 1))

hh %>% group_by(impr_toilet_type) %>% summarise(n = n()) %>%  mutate(pct = percent(n/sum(n), ndigits = 1))

hh %>% group_by(region_name, improved_toilet) %>% summarise(n = n()) %>% ungroup() %>%  group_by(region_name) %>% mutate(pct = n/sum(n)) %>% filter(improved_toilet == 1) %>% ungroup() %>% arrange(desc(pct))
# Apply sampling weights
svymean(~improved_toilet, DHSdesign, na.rm = TRUE)
svymean(~improved_water, DHSdesign, na.rm = TRUE)