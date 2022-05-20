# global.R ----------------------------------------------------------------
#
# Define global objects for the Shiny app.
#
# Heart Disease Data Portal v 0.1 - initial testing

# load libraries ----------------------------------------------------------

library(dplyr)
library(ggplot2)
library(glue)
library(htmltools)
library(leaflet)
# library(leafpop)
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

# hypertension rates
rate_data <- read_excel('data/AHA file with publication score_Pass1_11Apr2022.xlsx', na='N/A')
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

# for race, move the 'Other' category to the end
# oth_i <- which(grepl('other', race_categories, ignore.case = TRUE))
# race_categories <- c(race_categories[-oth_i], race_categories[oth_i])
# rm(oth_i)



# define the color palette and label format -------------------------------

pal <- colorBin(palette = "BuPu", domain = rate_data$Percent, bins = 8)

lab <- labelFormat(suffix = '%', transform = function(x) x * 100)


# define custom javascript functions --------------------------------------

# set the opacity of all 'path' polygons to 0
clearPolygonsJS <- "shinyjs.clearPolygons = function(){
    polygons = document.getElementsByTagName('path');
    for (i=0; i<polygons.length; i++) {
      polygons[i].setAttribute('opacity',0);
      polygons[i].setAttribute('fill-opacity',0);
    }
}"

# change the colors of the polygons and set their opacity to 0.6 
changeColorsJS <- "shinyjs.changeColors = function(params){
    districts = params[0];
    colors = params[1];
    for (i=0; i<districts.length; i++) {
      thisDistrict = districts[i];
	    element = document.getElementsByClassName(thisDistrict);
	    element[0].setAttribute('fill',colors[i]);
	    element[0].setAttribute('fill-opacity',0.6);
    }
}"
