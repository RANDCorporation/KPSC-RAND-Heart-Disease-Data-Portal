# ui.R --------------------------------------------------------------------
#
# Define the user interface of the app.
#
# Heart Disease Data Portal v 0.3 - incorporating QA edits

dashboardPage(
  title = 'KPSC-RAND Heart Disease Data Portal',
  dashboardHeader(title = HTML("<div style='float: left;'>KPSC-RAND Heart Disease Data Portal<div>"), titleWidth = "100%"),
  ## Sidebar content
  dashboardSidebar(
    tags$head(tags$style(type='text/css', ".slider-animate-button { float: left; font-size: 15pt; margin-top: 3px !important; } .sidebar .irs-min, .sidebar .irs-max {color: #fff !important;}")),
    width = 355,
    htmlOutput("sidebar_note1"),
    htmlOutput("sidebar_note2"),
    uiOutput("ageControls"),
    uiOutput("genderControls"),
    uiOutput("raceControls"),
    htmlOutput("sidebar_note3"),
    htmlOutput("sidebar_note4"),
    uiOutput("yearControls"),
    htmlOutput("sidebar_footnote")
  ),
  ## Body content
  dashboardBody(
    tags$head(tags$style(includeCSS("www/HDDP.css"))),
    useShinyjs(),
    extendShinyjs(script='defineGlobals.js', functions="defineGlobals"),
    extendShinyjs(script='changeColors.js', functions='changeColors'),
    extendShinyjs(script='changeYear.js', functions="changeYear"),
    extendShinyjs(script='displayRates.js', functions="displayRates"),
    tabsetPanel(
      tabPanel("Map",
               fluidRow(
                 fillPage(
                   tags$style(type = "text/css", "#map {height: calc(100vh - 98px) !important;} #geoSelect {height: calc(100vh - 100px) !important;}"),
                   fillRow(leafletOutput('map', width="100%", height="100%")
                   )
                 )
               )
      ),
      tabPanel("Time-Series Plots",
               fluidRow(
                 fillPage(
                   tags$style(type = "text/css", "#timeSeriesPlots {height: calc(100vh - 100px) !important;}"),
                   plotOutput("timeSeriesPlots", height = "100%"))
               )
      )
    )
  )
)
