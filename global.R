# global.R ----------------------------------------------------------------
#
# Define global objects for the Shiny app.


# load libraries ----------------------------------------------------------

library(dplyr)
library(ggplot2)
library(glue)
library(htmltools)
# library(knitr) # for kable function
# library(kableExtra)
library(leaflet)
library(leafpop)
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
    TRUE ~ paste0('Non-Hispanic ', Race)
  ))



# define lists for selectors ----------------------------------------------

age_categories <- unique(rate_data$Age)
gender_categories <- unique(rate_data$Gender)
race_categories <- unique(rate_data$RaceEth)
hispanic_categories <- unique(rate_data$Hispanic)
year_categories <- unique(rate_data$Year)

# for race, move the 'Other' category to the end
oth_i <- which(grepl('other', race_categories, ignore.case = TRUE))
race_categories <- c(race_categories[-oth_i], race_categories[oth_i])
rm(oth_i)



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

# removePolygonsJS <- "shinyjs.removePolygons = function(){
#     polygons = document.getElementsByTagName('path');
#     i = 0;
#     j = polygons.length;
#     while (i < j) {
# 	    element = polygons[i];
# 	    opacity = element.getAttribute('fill-opacity');
# 	    if (opacity==0) {
# 		    element.parentNode.removeChild(element);
# 	    } else {
# 	        i++;
# 	    }
# 	    j = polygons.length;
#     }
# }"

# change the colors of the 'path' objects and set their opacity to 0.6 
changeColorsJS <- "shinyjs.changeColors = function(params){
    colors = params[0];
    polygons = document.getElementsByTagName('path');
    for (i=0; i<polygons.length; i++) {
	    element = polygons[i];
	    element.setAttribute('fill',colors[i]);
	    element.setAttribute('fill-opacity',0.6);
    }
}"
