# server.R ----------------------------------------------------------------
# 
# Define the server logic for the app


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
                      opacity = 0.6)
    })
    
    
    # Get rates for the current year
    # Input dependencies: measure, geography, year
    rates <- reactive({
        # If Shiny tries to proceed with any of these missing, it'll throw an error and the app will break.
        req(input$age, input$gender, input$race, input$year)
        
        # Set parameters for determining which data to pull
        geo_abb <- input$geo %>% gsub("[a-z]|\\s","",.)
        
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
    
    # Create data table output
    output$ratesTable <- renderDT({
      # If Shiny tries to proceed with any of these missing, it'll throw an error and the app will break.
      req(input$age, input$gender, input$race, input$year)
      
      # Set parameters for determining which data to pull
      geo_abb <- input$geo %>% gsub("[a-z]|\\s","",.)
      
      # Filter rate data to the selected year
      df <- rate_data %>% filter(Age==input$age,
                                 Gender==input$gender,
                                 RaceEth==input$race,
                                 Year==input$year)
      
      df %>% 
        filter(HD_NAME!='_ALL_') %>% 
        select(HD_NAME, Percent)
    })
    
    
    # Add legend and color
    # Input dependencies: measure, geography, year
    observe(label = 'Add legend and color', x={
        
        req(input$year)
        
        # Add the proper shading
        # delay(10, js$changeColors(pal(rates())))
        hd_names <- paste0("HD-",gsub(' ', '-', names(rates())))
        delay(10, js$changeColors2(hd_names, pal(rates())))

    })
    
    # Add color when rates change
    # (this bit is only useful for the animation)
    # Input dependencies: measure, geography, year
    observe(label = 'Update colors', x={
        
        req(input$year)

        # Custom written function
        # js$changeColors(pal(rates()))
        hd_names <- paste0("HD-",gsub(' ', '-', names(rates())))
        js$changeColors2(hd_names, pal(rates()))
        
    })
    
})
