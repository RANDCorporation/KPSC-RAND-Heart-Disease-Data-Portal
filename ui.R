#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shinydashboard)
library(shinyjs)
library(leaflet)

# Custom javascript for clearing the colors
clearPolygonsJS <- "shinyjs.clearPolygons = function(){
    polygons = document.getElementsByTagName('path');
    for (i=0; i<polygons.length; i++) polygons[i].setAttribute('fill-opacity',0);
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
	    element.setAttribute('fill-opacity',0.5);
    }
}"
   
dashboardPage(
    dashboardHeader(title = "Heart Disease Data Portal", titleWidth = 300),
    ## Sidebar content
    dashboardSidebar(
        width = 300,
        sidebarMenu(
            menuItem("Map", tabName = "map", icon = icon("map")),
            menuItem("Time-series", tabName = "time-series", icon = icon("chart-line"))
        ),
        uiOutput("geoControls"),
        uiOutput("yearControls")
    ),
    ## Body content
    dashboardBody(
        useShinyjs(),
        extendShinyjs(text=clearPolygonsJS, functions="clearPolygons"),
        extendShinyjs(text=removePolygonsJS, functions="removePolygons"),
        extendShinyjs(text=changeColorsJS, functions="changeColors"),
        tabItems(
            # First tab content
            tabItem(tabName = "map",
                    fillPage(
                        tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;} #geoSelect {height: calc(100vh - 100px) !important;}"),
                        fillRow(flex=c(4,1),
                            leafletOutput('map', width="99%", height="100%")#,
                            #box(uiOutput("geoSelect"), width="100%", height="95%", solidHeader = TRUE)
                        )
                    )
                    #fillPage(
                    #    tags$style(type = "text/css", "#plot1 {height: calc(100vh - 80px) !important;}"),
                    #    leafletOutput('plot1', height = "100%", width = "100%")
                    #)
            ),
            
            # Second tab content
            tabItem(tabName = "time-series",
                    h2("Time-series tab content")
            )
        )
    )
)
