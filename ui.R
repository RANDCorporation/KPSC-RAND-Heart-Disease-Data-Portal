# ui.R --------------------------------------------------------------------
#
# Define the user interface of the app.
#
# Heart Disease Data Portal v 0.1 - initial testing


# bootstrapPage(
#   tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
#   leafletOutput("map", width = "100%", height = "100%"),
#   absolutePanel(bottom=20, left=20, width="20%", height="60%",
#                 id="controls",
#                 style="padding:15px",
#                 class = "panel panel-default",
#                 draggable = FALSE, 
#                 uiOutput("ageControls"),
#                 uiOutput("genderControls"),
#                 uiOutput("raceControls"),
#                 uiOutput("yearControls"),
#                 htmlOutput("sidebar_note"),
#                 useShinyjs(),
#                 extendShinyjs(text=changeColorsJS, functions="changeColors")),
#   absolutePanel(top=20, right=20, width="30%", height="70%",
#                 id="ratesTable",
#                 style="padding:15px",
#                 draggable=FALSE)
# )

# fluidPage(
#   
#   titlePanel("Heart Disease Data Portal"),
#   
#   sidebarLayout(
#     
#     sidebarPanel(
#       uiOutput("ageControls"),
#       uiOutput("genderControls"),
#       uiOutput("raceControls"),
#       uiOutput("yearControls"),
#       htmlOutput("sidebar_note")
#     ),
#     
#     mainPanel(
#       tags$head(
#         tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
#       ),
#       useShinyjs(),
#       extendShinyjs(text=changeColorsJS, functions="changeColors"),
#       tabsetPanel(
#         tabPanel("Map", 
#                  fluidRow(
#                    fillPage(
#                      tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;} #geoSelect {height: calc(100vh - 100px) !important;}"),
#                      fillRow(flex=c(4,1), leafletOutput('map', width="99%", height="100%"))
#                    )
#                  )
#         ),
#         tabPanel("Time-Series Plots")
#       )
#     )
#   )
# )

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
    tabsetPanel(
      tabPanel("Map",
               fluidRow(
                 fillPage(
                   tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;} #geoSelect {height: calc(100vh - 100px) !important;}"),
                   fillRow(flex=c(4,1), leafletOutput('map', width="99%", height="100%"))
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
