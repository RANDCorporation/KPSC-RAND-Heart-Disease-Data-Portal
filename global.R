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


# define the color palette and label format -------------------------------

pal <- colorBin(palette = "BuPu", domain = rate_data$Percent, bins = 8)

lab <- labelFormat(suffix = '%', transform = function(x) x * 100)


# define custom javascript functions --------------------------------------

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

# change the year being labeled on the map
changeYearJS <- "shinyjs.changeYear = function(params){
    newYearHTML = params[0];
	  yearLabel = document.getElementsByClassName('year-label');
	  yearLabel[0].innerHTML = newYearHTML;
}"

defineGlobalsJS <- "shinyjs.defineGlobals = function(params) {
    // define a global variable containing the highlighted health district
    highlightedDistrict = '';
}"

# display health district names and hypertension rates on mouseover
displayRatesJS <- "shinyjs.displayRates = function(params) {
    // pull parameters and define empty html for mouseout
    districts = params[0];
    newHTML = params[1];
    emptyHTML = '<div><style> .leaflet-control.rate-label { transform: translate(20px,-90px); position: fixed !important; left: 350; text-align: center; padding-left: 10px;  padding-right: 10px;  background: rgba(255,255,255,0.75); font-weight: bold; font-size: 24px; } </style>Mouse over a district to display rates</div>';
    
    // loop over each district and assign mouseover and mouseout functions
    for (i=0; i<districts.length; i++) {
      thisDistrict = districts[i];
      thisHTML = newHTML[i]
	    element = document.getElementsByClassName(thisDistrict);
	    
	    // if the district is currently highlighted, update the label
      if (highlightedDistrict==thisDistrict) {
        rateLabel = document.getElementsByClassName('rate-label');
	      rateLabel[0].innerHTML = thisHTML;
      }
	    
	    // on mouseover, add the label
	    element[0].onmouseover = ( function(new_html, currentDistrict) {
        return function() { 
          this.setAttribute('stroke-width', 5)
          this.parentNode.appendChild(this);
          highlightedDistrict = currentDistrict;
          rateLabel = document.getElementsByClassName('rate-label');
	        rateLabel[0].innerHTML = new_html;
        }
      }) (thisHTML, thisDistrict);
      
      // on mouseout, remove the label
      element[0].onmouseout = ( function(new_html) {
        return function() { 
          this.setAttribute('stroke-width', 1)
          highlightedDistrict = '';
          rateLabel = document.getElementsByClassName('rate-label');
	        rateLabel[0].innerHTML = new_html;
        }
      }) (emptyHTML);
      
    }
    
}"