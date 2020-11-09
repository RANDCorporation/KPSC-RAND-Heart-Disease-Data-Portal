# global.R
# global objects for Shiny app

# load libraries
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


# selection choices for measure and geography
measChoices <- c("Hypertension", "Hypertension - controlled", "Hypertension - uncontrolled")
geoChoices <- c("Health District", "Census Designated Place")

# Custom javascript
clearPolygonsJS <- "shinyjs.clearPolygons = function(){
    polygons = document.getElementsByTagName('path');
    for (i=0; i<polygons.length; i++) {
      polygons[i].setAttribute('opacity',0);
      polygons[i].setAttribute('fill-opacity',0);
    }
}"

removePolygonsJS <- "shinyjs.removePolygons = function(){
    polygons = document.getElementsByTagName('path');
    i = 0;
    j = polygons.length;
    while (i < j) {
	    element = polygons[i];
	    opacity = element.getAttribute('fill-opacity');
	    if (opacity==0) {
		    element.parentNode.removeChild(element);
	    } else {
	        i++;
	    }
	    j = polygons.length;
    }
}
"

changeColorsJS <- "shinyjs.changeColors = function(params){
    colors = params[0];
    polygons = document.getElementsByTagName('path');
    for (i=0; i<polygons.length; i++) {
	    element = polygons[i];
	    element.setAttribute('fill',colors[i]);
	    element.setAttribute('fill-opacity',0.6);
    }
}"
