# ui.R --------------------------------------------------------------------
#
# Define the user interface of the app.
#
# Heart Disease Data Portal v 0.1 - initial testing


bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(bottom=20, left=20, width="20%", height="60%",
                id="controls",
                style="padding:15px",
                class = "panel panel-default",
                draggable = FALSE, 
                uiOutput("ageControls"),
                uiOutput("genderControls"),
                uiOutput("raceControls"),
                uiOutput("yearControls"),
                htmlOutput("sidebar_note"),
                useShinyjs(),
                extendShinyjs(text=changeColorsJS, functions="changeColors")),
  absolutePanel(top=20, right=20, width="30%", height="70%",
                id="ratesTable",
                style="padding:15px",
                draggable=FALSE)
)

# 
# dashboardPage(
#     dashboardHeader(title = "Heart Disease Data Portal", titleWidth = 300),
#     ## Sidebar content
#     dashboardSidebar(
#         width = 300,
#         uiOutput("ageControls"),
#         uiOutput("genderControls"),
#         uiOutput("raceControls"),
#         uiOutput("yearControls"),
#         htmlOutput("sidebar_note")
#     ),
#     ## Body content
#     dashboardBody(
#         useShinyjs(),
#         extendShinyjs(text=clearPolygonsJS, functions="clearPolygons"),
#         # extendShinyjs(text=removePolygonsJS, functions="removePolygons"),
#         extendShinyjs(text=changeColorsJS, functions="changeColors"),
#         fluidRow(
#           fillPage(
#             tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;} #geoSelect {height: calc(100vh - 100px) !important;}"),
#             fillRow(flex=c(4,1),
#                   leafletOutput('map', width="99%", height="100%")
#             )
#           )
#         )
#     )
# )
