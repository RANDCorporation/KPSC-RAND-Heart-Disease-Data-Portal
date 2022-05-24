# ui.R --------------------------------------------------------------------
#
# Define the user interface of the app.
#
# Heart Disease Data Portal v 0.1 - initial testing

dashboardPage(
  dashboardHeader(title = "Kaiser Permanente - RAND Heart Disease Data Portal", titleWidth = "100%"),
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
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
    ),
    useShinyjs(),
    extendShinyjs(text=changeColorsJS, functions="changeColors"),
    extendShinyjs(text=changeYearJS, functions="changeYear"),
    extendShinyjs(text=displayRatesJS, functions="displayRates"),
    tabsetPanel(
      tabPanel("Map",
               fluidRow(
                 fillPage(
                   tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;} #geoSelect {height: calc(100vh - 100px) !important;}"),
                   fillRow(flex=c(4,1), 
                           leafletOutput('map', width="99%", height="100%")
                   )
                 )
               )
      ),
      tabPanel("Time-Series Plots",
               fluidRow(
                 fillPage(
                   tags$style(type = "text/css", "#timeSeriesPlots {height: calc(100vh - 110px) !important;}"),
                   plotOutput("timeSeriesPlots", height = "100%"))
               )
      )
    )
  )
)
