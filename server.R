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
            addPolygons(layerId = geodata$HD_NAME,
                        group = "Health Districts",
                        color = "#444444", 
                        weight = 0.75, 
                        # weight = 0.25, 
                        smoothFactor = 0.5,
                        opacity = 1.0, fillOpacity = 0.0,
                        highlightOptions = NULL,
                        # highlightOptions = highlightOptions(
                        #   weight = 2,
                        #   bringToFront = TRUE),
                        label = paste0(geodata$HD_NAME, ' Health District'),
                        labelOptions = labelOptions(
                          noHide = FALSE,
                          style = list("font-weight" = "normal", padding = "3px 8px"),
                          textsize = "15px",
                          direction = "auto"),
                        options = pathOptions(className = paste0("HD-",gsub(' ', '-', geodata$HD_NAME)))) %>%
        addPolylines(data = freeways, 
                     group = "Display Freeways",
                     color = "#ff0000",
                     opacity = 0.15, 
                     weight = 1) %>%
            addLegend("bottomright",
                      pal = pal,
                      values = ~rate_data$Percent,
                      labFormat = lab,
                      title = "Rate",
                      na.label = "Censored",
                      opacity = 0.6) %>%
            addLayersControl(overlayGroups = c("Display Freeways"),
                             options = layersControlOptions(collapsed = FALSE))
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
      
      # Separate out the data for LA County as a whole
      plotData_all <- plotData %>% filter(HD_NAME=='_ALL_') %>% select(-HD_NAME) %>% mutate(Entity="LA County")
      plotData <- plotData %>% filter(HD_NAME!='_ALL_') %>% mutate(Entity = "Health District")
      
      plotData %>% 
        ggplot(aes(x=Year, y=Percent, color=Entity)) +
        geom_line() +
        geom_line(data = plotData_all, aes(x=Year, y=Percent, color=Entity)) + 
        scale_y_continuous(labels = scales::label_percent(accuracy = 1)) + 
        scale_color_manual(values = c("black", "steelblue")) + 
        facet_wrap(vars(HD_NAME), ncol=4) + 
        labs(caption = "Note: Health Districts with censored values will have missing lines.") + 
        theme_minimal() + 
        theme(plot.caption = element_text(hjust = 0, size=12))
      
    })
    
})
