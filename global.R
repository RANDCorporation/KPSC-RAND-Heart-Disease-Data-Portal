# global.R ----------------------------------------------------------------
#
# Define global objects for the Shiny app.
#
# Heart Disease Data Portal v 1.0 - Pushing to GitHub

# load libraries ----------------------------------------------------------

library(dplyr)
library(ggplot2)
library(glue)
library(htmltools)
library(htmlwidgets)
library(leaflet)
library(magrittr)
library(readxl)
library(sf)
library(shiny)
library(shinydashboard)
library(shinyjs)
library(stringr)
library(tidyr)


# load the data -----------------------------------------------------------

# Health District boundaries
geodata <- st_read('data/geodata/HD_2012_WGS84/Health_Districts_2012_WGS84.shp')

# LA County freeway boundaries
freeways <- st_read('data/geodata/Master_Plan_of_Highways/Master_Plan_of_Highways.shp')

# hypertension prevalence
rate_data <- read_excel('data/data_template.xlsx', na='N/A')
rate_data %<>% rename(Year = year,
                      HD_NAME = HD2012,
                      Age = age_c,
                      Gender = GENDER,
                      Race = race_c,
                      Hispanic = hisp,
                      Percent = percent) %>%
  mutate(RaceEth = case_when(
    Hispanic=='Hispanic' ~ 'Hispanic',
    TRUE ~ Race
  ))


# define lists for selectors ----------------------------------------------

age_categories <- unique(rate_data$Age)
gender_categories <- unique(rate_data$Gender)
race_categories <- unique(rate_data$RaceEth)
hispanic_categories <- unique(rate_data$Hispanic)
year_categories <- unique(rate_data$Year)


# define the color palette and label format -------------------------------

pal <- colorBin(palette = "BuPu", domain = rate_data$Percent, bins = 8)

lab <- labelFormat(suffix = '%', transform = function(x) x * 100)

