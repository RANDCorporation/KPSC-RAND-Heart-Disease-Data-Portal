#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

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
            #value=ifelse(is.na(input$year), min(yearChoices), input$year), 
            step=1, sep="", ticks=FALSE, 
            animate=animationOptions(interval=1000))
    })
    
    # sidebar note
    output$sidebar_note <- renderUI({
        HTML("<p style='margin:15px; color:gray'>Hint: press the play button (above-right) to display an animation of rates over time.</p><p style='margin:15px; color:gray'>Click on a shaded region on the map to display a time-series plot of rates for that region.</p>")
    })
    
    # create base map
    output$map <- renderLeaflet({
        leaflet(data = geodata) %>%
            #addProviderTiles("CartoDB.Positron", group="base") %>%
            addMapPane(name = "polygons", zIndex = 410) %>% 
            addMapPane(name = "maplabels", zIndex = 420) %>% # higher zIndex means the labels are rendered on top of the polygons
            addProviderTiles("CartoDB.PositronNoLabels") %>%
            addProviderTiles("CartoDB.PositronOnlyLabels", 
                             options = leafletOptions(pane = "maplabels"),
                             group = "Place names") %>%
            setView(lng=-118.3, lat=34.1, zoom=10) %>%
            addPolygons(layerId = geodata$HD_NAME,
                        group = "Rates",
                        color = "#444444", 
                        weight = 0.25, smoothFactor = 0.5,
                        opacity = 1.0, fillOpacity = 0.0) %>%
            addLegend("bottomleft",
                      pal = pal,
                      values = ~rate_data$Percent,
                      labFormat = lab,
                      title = "Rate",
                      opacity = 0.6)
    })
    
    
    # Create popup graphs
    # Input dependencies: measure, geography
    get_popup_graphs <- reactive({
        
        geographies <- levels(geodata$HD_NAME)

        ymin <- min(rate_data$Percent, na.rm=TRUE)
        ymax <- max(rate_data$Percent, na.rm=TRUE)
        xmin <- min(rate_data$Year, na.rm=TRUE)
        xmax <- max(rate_data$Year, na.rm=TRUE)
        
        TRUE

        # lapply(geographies, function(gg) {
        #     if (gg %in% rate_data$HD_NAME) {
        #         myplot <- rate_data %>%
        #             filter(HD_NAME==gg) %>%
        #             ggplot(aes(x=YEAR, y=Percent)) +
        #             geom_line() +
        #             ylim(ymin, ymax) +
        #             theme_minimal() +
        #             labs(title = gg, x="Year", y="Rate") + 
        #             scale_x_continuous(breaks=seq(xmin, xmax, 1))
        #         ggsave(glue('plots/{input$measure}/{input$geo}/{gg}.png'), width=6, height=4, dpi=75)
        #         # myplot
        #         TRUE
        #     } else {
        #         myplot <- data.frame(x=1,y=1,z="No data available") %>%
        #             ggplot(aes(x=x,y=y,label=z)) +
        #             geom_label() +
        #             theme_void() +
        #             labs(title = gg)
        #         ggsave(glue('plots/{input$measure}/{input$geo}/{gg}.png'), width=4, height=4, dpi=75)
        #         # myplot
        #         TRUE
        #     }
        # })
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
        return(values)
    })
    

    # # Add popup graphs
    # # Input dependencies: measure, geography
    # observe(label = 'Add popups', x={
    #     
    #     req(input$geo, input$measure)
    #     
    #     # Clear any existing polygons 
    #     # (this doesn't remove them per se but rather makes them invisible, which makes the transition look better)
    #     # js$clearPolygons()
    #     
    #     # Clear any existing popups
    #     # leafletProxy("map", data = geodata()) %>% leaflet::invokeMethod(data, "clearPopups")
    #     
    #     # Get popup graphs
    #     makegraphs <- get_popup_graphs()
    #     myplots <- lapply(levels(geodata$HD_NAME), function(gg) glue('plots/{input$measure}/{input$geo}/{gg}.png'))
    #     
    #     # Add polygons
    #     leafletProxy("map", data = geodata) %>%
    #         # clearShapes() %>%
    #         # addPolygons(layerId = geodata()$HD_NAME,
    #         #             group = "Rates",
    #         #             color = "#444444", 
    #         #             weight = 0.25, smoothFactor = 0.5,
    #         #             opacity = 1.0, fillOpacity = 0.0) %>%
    #         leaflet::invokeMethod(data, "clearPopups") %>% 
    #         addPopupImages(myplots, group="Rates") # %>%
    #         # clearControls() %>% 
    #         # addLegend("bottomleft",
    #         #           pal = pal(),
    #         #           values = ~rate_data$Percent,
    #         #           title = "Rate",
    #         #           opacity = 0.6)
    #     
    #     # Uncomment this to allow toggling between panes
    #     # One issue is that if the Rates are unchecked and then checked again, the colors aren't restored
    #     # addLayersControl(overlayGroups = c("Place names", "Rates")) %>%
    #     # setView(lng=-118.3, lat=34.1, zoom=10) %>%
    #     # addLegend("bottomleft",
    #     #           pal = pal(),
    #     #           values = ~rate_data$Percent,
    #     #           title = "Rate",
    #     #           opacity = 0.6)
    #     
    # })    
    
    
    # Add legend and color
    # Input dependencies: measure, geography, year
    observe(label = 'Add legend and color', x={
        
        req(input$year)
        
        # Add legend
        # delay(5, leafletProxy("map", data = geodata) %>%
        #           clearControls() %>%
        #           addLegend("bottomleft",
        #                     pal = pal(),
        #                     values = ~rate_data$Percent,
        #                     title = "Rate",
        #                     opacity = 0.6))
        
        # Add the proper shading
        delay(10, js$changeColors(pal(rates())))

    })
    
    # Add color when rates change
    # (this bit is only useful for the animation)
    # Input dependencies: measure, geography, year
    observe(label = 'Update colors', x={
        
        req(input$year)

        # Custom written function
        js$changeColors(pal(rates()))
        
    })
    
})
