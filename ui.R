#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

dashboardPage(
    dashboardHeader(title = "Heart Disease Data Portal", titleWidth = 300),
    ## Sidebar content
    dashboardSidebar(
        width = 300,
        uiOutput("ageControls"),
        uiOutput("genderControls"),
        uiOutput("raceControls"),
        uiOutput("yearControls"),
        htmlOutput("sidebar_note")
    ),
    ## Body content
    dashboardBody(
        useShinyjs(),
        extendShinyjs(text=clearPolygonsJS, functions="clearPolygons"),
        # extendShinyjs(text=removePolygonsJS, functions="removePolygons"),
        extendShinyjs(text=changeColorsJS, functions="changeColors"),
        fluidRow(
          fillPage(
            tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;} #geoSelect {height: calc(100vh - 100px) !important;}"),
            fillRow(flex=c(4,1),
                  leafletOutput('map', width="99%", height="100%")
            )
          )
        )
    )
)
