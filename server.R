# server.R ----------------------------------------------------------------
# 
# Define the server logic for the app
#
# Heart Disease Data Portal v 0.1 - initial testing


# Define server logic
shinyServer(function(input, output) {
    # If this option is set to true, you can hit Ctrl+F3 (Command+fn+F3) to view a reactive log of the app
    # See https://shiny.rstudio.com/articles/debugging.html
    options(shiny.reactlog = TRUE)
    
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
            value=min(year_categories),
            step=1, sep="", ticks=FALSE, 
            animate=animationOptions(interval=500))
    })
    
    # sidebar note
    output$sidebar_note <- renderUI({
        HTML("<p style='margin:15px; color:gray'>Hint: press the play button (above-right) to display an animation of rates over time.</p>")
    })
    
    # create base map
    output$map <- renderLeaflet({
        leaflet(data = geodata) %>%
            addMapPane(name = "polygons", zIndex = 410) %>% 
            addMapPane(name = "maplabels", zIndex = 420) %>% # higher zIndex means the labels are rendered on top of the polygons
            addProviderTiles("CartoDB.PositronNoLabels") %>%
            addProviderTiles("CartoDB.PositronOnlyLabels", 
                             options = leafletOptions(pane = "maplabels"),
                             group = "Place names") %>%
            setView(lng=-118.4, lat=34.1, zoom=10) %>% 
            addPolylines(data = freeways, 
                     color = "#222222", 
                     opacity = 0.05, 
                     weight = 5) %>%
            addPolygons(layerId = geodata$HD_NAME,
                        group = "Rates",
                        color = "#444444", 
                        weight = 0.25, smoothFactor = 0.5,
                        opacity = 1.0, fillOpacity = 0.0,
                        highlightOptions = NULL,
                        label = paste0(geodata$HD_NAME, ' Health District'),
                        labelOptions = labelOptions(
                          style = list("font-weight" = "normal", padding = "3px 8px"),
                          textsize = "15px",
                          direction = "auto"),
                        options = pathOptions(className = paste0("HD-",gsub(' ', '-', geodata$HD_NAME)))) %>%
            addLegend("bottomright",
                      pal = pal,
                      values = ~rate_data$Percent,
                      labFormat = lab,
                      title = "Rate",
                      na.label = "Censored",
                      opacity = 0.6)
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
    
    # Add legend and color
    # Input dependencies: measure, geography, year
    observe(label = 'Add legend and color', x={
        
        req(input$year)
        
        # Add the proper shading
        hd_names <- paste0("HD-",gsub(' ', '-', names(rates())))
        delay(10, js$changeColors(hd_names, pal(rates())))

    })
    
    # Add color when rates change
    # (this bit is only useful for the animation)
    # Input dependencies: measure, geography, year
    observe(label = 'Update colors', x={
        
        req(input$year)

        # Custom written function
        hd_names <- paste0("HD-",gsub(' ', '-', names(rates())))
        js$changeColors(hd_names, pal(rates()))
        
    })
    
    output$timeSeriesPlots <- renderPlot({
      
      # If Shiny tries to proceed with any of these missing, it'll throw an error and the app will break.
      req(input$age, input$gender, input$race, input$year)
      
      # Filter rate data to the selected year
      plotData <- rate_data %>% filter(Age==input$age,
                                       Gender==input$gender,
                                       RaceEth==input$race) %>%
        mutate(Year = lubridate::ymd(glue('{Year}-01-01')))
      
      plotData %>% 
        ggplot(aes(x=Year, y=Percent)) +
        geom_line() +
        scale_y_continuous(labels = scales::label_percent(accuracy = 1)) + 
        facet_wrap(vars(HD_NAME), ncol=4) + 
        theme_minimal()
      
    })
    
})
