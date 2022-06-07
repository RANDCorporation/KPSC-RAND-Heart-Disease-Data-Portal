# server.R ----------------------------------------------------------------
# 
# Define the server logic for the app
#
# Heart Disease Data Portal v 0.3 - incorporating QA edits


# Define server logic
shinyServer(function(input, output) {
    # If this option is set to true, you can hit Ctrl+F3 (Command+fn+F3) to view a reactive log of the app
    # See https://shiny.rstudio.com/articles/debugging.html
    options(shiny.reactlog = TRUE)
    
    # run JS to define global JS variables
    # this is used to track the highlighted health district
    js$defineGlobals()
  
    # Selectors
    output$ageControls <- renderUI({
        selectInput("age", "Age", choices = age_categories, selected = age_categories[1])
    })
    
    output$genderControls <- renderUI({
        selectInput("gender", "Gender", choices = gender_categories, selected = gender_categories[1])
    })
    
    output$raceControls <- renderUI({
        selectInput("race", "Race/Ethnicity", choices = race_categories, selected = race_categories[1])
    })
    
    output$yearControls <- renderUI({
        sliderInput("year", "Year", min=min(year_categories), max=max(year_categories), 
            value=max(year_categories),
            step=1, sep="", ticks=FALSE, 
            animate=animationOptions(interval=500))
    })
    
    # intro note
    output$intro_note <- renderUI({
      HTML("<p style='margin-left:15px; margin-top:15px; margin-right:15px; margin-bottom:0px; color:black; font-size: 15px; font-weight: bold;'>Select a group to display hypertension rates by health district in LA County:</p>")
    })
    
    # sidebar note
    output$sidebar_note <- renderUI({
        HTML("<p style='margin-left:15px; margin-top:0px; margin-right:15px; margin-bottom:0px; line-height: 1.3; color:black'>Press the play button (above-right) to display an animation of hypertension rates over time.</p>")
    })
    
    # sidebar footnote
    output$sidebar_footnote <- renderUI({
      HTML("<p style='margin:15px; font-size: 13.5px; line-height: 1.3; color:black; position: absolute; bottom: 0'>*Rates are not displayed when the number of Kaiser Permanente patients in a given area is too low. This is done to protect patient privacy.</p>")
    })
    
    # create base map
    output$map <- renderLeaflet({
      
        leaflet(data = geodata, options = leafletOptions(zoomControl = FALSE)) %>%
            addMapPane(name = "polygons", zIndex = 410) %>% 
            addMapPane(name = "maplabels", zIndex = 420) %>% # higher zIndex means the labels are rendered on top of the polygons
            addProviderTiles("CartoDB.PositronNoLabels") %>%
            addProviderTiles("CartoDB.PositronOnlyLabels", 
                             options = leafletOptions(pane = "maplabels"),
                             group = "Place names") %>%
            setView(lng=-118.2, lat=34.1, zoom=10) %>% 
            addPolylines(data = freeways, 
                     group = "Display Freeways",
                     color = "#ff0000",
                     opacity = 0.2, 
                     weight = 1) %>%
            addPolygons(layerId = geodata$HD_NAME,
                        group = "Health Districts",
                        color = "#444444", 
                        weight = 1, 
                        smoothFactor = 0.5,
                        opacity = 1.0, fillOpacity = 0.0,
                        highlightOptions = NULL,
                        options = pathOptions(className = paste0("HD-",gsub(' ', '-', geodata$HD_NAME)))) %>%
            addLegend("bottomright",
                      pal = pal,
                      values = ~rate_data$Percent,
                      labFormat = lab,
                      title = "Hypertension Rate",
                      na.label = "Not Available*",
                      opacity = 0.6) %>%
            addLayersControl(overlayGroups = c("Display Freeways"),
                             options = layersControlOptions(collapsed = FALSE)) %>%
            addControl(tags$div(
              tags$style(HTML("")), HTML("")
              ), position = "topleft", className="year-label") %>%
            addControl(HTML("<div><style> .leaflet-control.rate-label { transform: translate(20px,-90px); position: fixed !important; left: 350; text-align: center; padding-left: 10px;  padding-right: 10px;  background: rgba(255,255,255,0.75); font-weight: bold; font-size: 24px; } </style>Mouse over a district to display rates</div>"), 
                       position = "bottomleft", className="rate-label") %>%
            htmlwidgets::onRender("function(el, x) {
              L.control.zoom({ position: 'topright' }).addTo(this)
            }")
    })
    
    
    # Get rates for the current year
    # Input dependencies: measure, geography, year
    rates <- reactive({
        # If Shiny tries to proceed with any of these missing, it'll throw an error and the app will break.
        req(input$age, input$gender, input$race, input$year)
        
        # Filter rate data to the selected year
        df <- rate_data %>% filter(Age==input$age,
                                   Gender==input$gender,
                                   RaceEth==input$race,
                                   Year==input$year)
        
        # Return values of the desired variable (currently Percent) in the same order as the geographies
        values <- df$Percent[match(geodata$HD_NAME, df$HD_NAME)]
        names(values) <- df$HD_NAME[match(geodata$HD_NAME, df$HD_NAME)]
        return(values)
    })
    
    # Add color
    # Input dependencies: measure, geography, year
    observe(label = 'Add color', x={
        
        req(input$year)
        
        # Add the proper shading
        hd_names <- paste0("HD-",gsub(' ', '-', names(rates())))
        
        js$changeColors(hd_names, pal(rates()))
        yearLabelHTML <- paste0("<div><style>
        .leaflet-control.year-label { 
          transform: translate(20px,0px);
          position: fixed !important;
          left: 350;
          text-align: center;
          padding-left: 10px; 
          padding-right: 10px; 
          background: rgba(255,255,255,0.75);
          font-weight: bold;
          font-size: 42px;
        }
        </style>", 
        input$year, 
        "</div>")
        
        js$changeYear(yearLabelHTML)
        
        # add a label with the health district name and hypertension rate
        rateLabelHTML <- paste0("<div><style> .leaflet-control.rate-label { transform: translate(20px,-90px); position: fixed !important; left: 350; text-align: center; padding-left: 10px;  padding-right: 10px;  background: rgba(255,255,255,0.75); font-weight: bold; font-size: 24px; } </style>", 
                                names(rates()), " Health District: ", 
                                scales::percent(rates(), accuracy=0.1) %>% replace_na('Not Available*'),
                                "</div>")
        
        js$displayRates(hd_names, rateLabelHTML)

    })
    

    # Create plots for the time series tab
    output$timeSeriesPlots <- renderPlot({
      
      # If Shiny tries to proceed with any of these missing, it'll throw an error and the app will break.
      req(input$age, input$gender, input$race)
      
      # Filter rate data to the selected year
      plotData <- rate_data %>% filter(Age==input$age,
                                       Gender==input$gender,
                                       RaceEth==input$race) %>%
        mutate(Year = lubridate::ymd(glue('{Year}-01-01')))
      
      # Separate out the data for LA County as a whole
      plotData_all <- plotData %>% filter(HD_NAME=='_ALL_') %>% select(-HD_NAME) %>% mutate(Entity="LA County")
      plotData <- plotData %>% filter(HD_NAME!='_ALL_') %>% mutate(Entity = "Health District")
      
      # drop health districts with censored values
      censored <- plotData %>% filter(is.na(Percent)) %>% pull(HD_NAME) %>% unique()
      plotData <- plotData %>% filter(!(HD_NAME %in% censored))
      
      # if there are no districts remaining, display an error message.
      if (nrow(plotData)==0) {
        validate("Sorry - there are no health districts with enough patients to display data for the selected group.")
      }
      
      plotData %>% 
        ggplot(aes(x=Year, y=Percent, color=Entity)) +
        geom_line() +
        geom_line(data = plotData_all, aes(x=Year, y=Percent, color=Entity)) + 
        scale_y_continuous(labels = scales::label_percent(accuracy = 1)) + 
        scale_color_manual(values = c("black", "steelblue")) + 
        facet_wrap(vars(HD_NAME), ncol=4) + 
        labs(caption = ifelse(length(censored > 0), "Note: Health districts with too few patients are excluded.", "")) + 
        theme_minimal() + 
        theme(plot.caption = element_text(hjust = 0, size=12))
      
    })
    
})
