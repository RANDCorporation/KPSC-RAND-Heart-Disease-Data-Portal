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
    # options(shiny.reactlog = TRUE)
    
    # Selectors
    output$measureControls <- renderUI({
        # measChoices <- list.files("data/Rates_v3")
        tagList(
            selectInput("measure", "Measure", choices = measChoices, 
                        selected = measChoices[1])
                        # selected = ifelse(is.na(input$measure), measChoices[1], input$measure))
        )
    })
    
    output$geoControls <- renderUI({
        measChoice1 <- list.files("data/Rates_v3")[1]
        # geoChoices <- list.files(glue("data/Rates_v3/{measChoice1}"))
        tagList(
            selectInput("geo", "Geography", choices = geoChoices, 
                        selected = geoChoices[1])
                        # selected = ifelse(is.na(input$geo), geoChoices[1], input$geo))
        )
    })
    
    output$yearControls <- renderUI({
        measChoice1 <- measChoices[1]
        geoChoice1 <- geoChoices[1]
        yearChoices <- list.files(glue("data/Rates_v3/{measChoice1}/{geoChoice1}")) %>% as.numeric
        tagList(
            sliderInput("year", "Year", min=min(yearChoices), max=max(yearChoices), 
                        value=min(yearChoices),
                        #value=ifelse(is.na(input$year), min(yearChoices), input$year), 
                        step=1, sep="", ticks=FALSE, 
                        animate=animationOptions(interval=1000))
        )
    })
    
    # Read in geodata
    geodata <- reactive({
            
        req(input$geo)
        # Set parameters for determining which data to pull
        geo <- input$geo
        
        if (geo=="Health District") {
            # Read in LA County Health District shapefile
            # Originally from https://egis3.lacounty.gov/dataportal/2012/03/01/health-districts-hd-2012/
            # Converted into WGS 84 projection using QGIS
            gd <- st_read('data/geodata/HD_2012_WGS84/Health_Districts_2012_WGS84.shp')
            #gd <- st_read('data/geodata/HD_2012_WGS84_noCI/Health_Districts_2012_WGS84_noCI.shp')
            gd %<>% rename(GEO_VALUE = HD_NAME) %>% arrange(GEO_VALUE)
        } else if (geo=="Census Designated Place") {
            gd <- st_read('data/geodata/CENSUS_DESIGNATED_PLACES_2010_WGS84/CENSUS_DESIGNATED_PLACES_2010_WGS84.shp')
            gd %<>% rename(GEO_VALUE = NAME) %>% arrange(GEO_VALUE)
        }
        
        # calculate centroids of each geographic unit (for placing popups)
        gd$centroid <- st_centroid(gd)$geometry
        
        return(gd)
    })
    
    # Read in data across all years
    # Input dependencies: measure, geography
    rate_data <- reactive({
        geo_abb <- input$geo %>% gsub("[a-z]|\\s","",.)
        yearChoices <- list.files(glue("data/Rates_v3/{input$measure}/{input$geo}")) %>% as.numeric
        lapply(yearChoices, function(year) {
            read_excel(glue('data/Rates_v3/{input$measure}/{input$geo}/{year}/HBP_{geo_abb}_{year}.xlsx'))
        }) %>% Reduce(rbind, .)
    })
    
    # Create color palette
    # Input dependencies: measure, geography
    pal <- reactive({colorBin(palette = "BuPu", domain = rate_data()$OVERALL, bins = 8)})
    
    # Create popup graphs
    # Input dependencies: measure, geography
    # get_popup_graphs <- reactive({
    #     geographies <- levels(geodata()$GEO_VALUE)
    # 
    #     ymin <- min(rate_data()$OVERALL, na.rm=TRUE)
    #     ymax <- max(rate_data()$OVERALL, na.rm=TRUE)
    # 
    #     lapply(geographies, function(gg) {
    #         if (gg %in% rate_data()$GEO_VALUE) {
    #             myplot <- rate_data() %>%
    #                 filter(GEO_VALUE==gg) %>%
    #                 ggplot(aes(x=YEAR, y=OVERALL)) +
    #                 geom_line() +
    #                 ylim(ymin, ymax) +
    #                 theme_minimal() +
    #                 labs(title = gg)
    #             ggsave(glue('plots/{input$measure}/{input$geo}/{gg}.png'), width=4, height=4, dpi=75)
    #             myplot
    #         } else {
    #             myplot <- data.frame(x=1,y=1,z="No data available") %>%
    #                 ggplot(aes(x=x,y=y,label=z)) +
    #                 geom_label() +
    #                 theme_void() +
    #                 labs(title = gg)
    #             ggsave(glue('plots/{input$measure}/{input$geo}/{gg}.png'), width=4, height=4, dpi=75)
    #             myplot
    #         }
    #     })
    # })
    
    # Get rates for the current year
    # Input dependencies: measure, geography, year
    rates <- reactive({
        # If Shiny tries to proceed with any of these missing, it'll throw an error and the app will break.
        req(input$measure, input$geo, input$year)
        
        # Set parameters for determining which data to pull
        geo_abb <- input$geo %>% gsub("[a-z]|\\s","",.)
        
        # Filter rate data to the selected year
        df <- rate_data() %>% filter(YEAR==input$year)
        
        # Return values of the desired variable (currently OVERALL) in the same order as the geographies
        values <- df$OVERALL[match(geodata()$GEO_VALUE, df$GEO_VALUE)]
        return(values)
    })
    
    output$map <- renderLeaflet({
        # Create plot
        leaflet() %>%
            #addProviderTiles("CartoDB.Positron", group="base") %>%
            addMapPane(name = "polygons", zIndex = 410) %>% 
            addMapPane(name = "maplabels", zIndex = 420) %>% # higher zIndex rendered on top
            addProviderTiles("CartoDB.PositronNoLabels") %>%
            addProviderTiles("CartoDB.PositronOnlyLabels", 
                             options = leafletOptions(pane = "maplabels"),
                             group = "Place names") %>%
            setView(lng=-118.3, lat=34.1, zoom=10) 
    })
    
    # Add polygons when geodata is loaded
    # Input dependencies: measure, geography (measure is only necessary for the popup info)
    observe({

        # Clear any existing polygons 
        # (this doesn't remove them per se but rather makes them invisible, which makes the transition look better)
        js$clearPolygons()
        
        # Clear any existing popups
        # leafletProxy("map", data = geodata()) %>% leaflet::invokeMethod(data, "clearPopups")
        
        # Get popup graphs
        # myplots <- get_popup_graphs()
        myplots <- lapply(levels(geodata()$GEO_VALUE), function(gg) glue('plots/{input$measure}/{input$geo}/{gg}.png'))
        
        # Add polygons
        leafletProxy("map", data = geodata()) %>%
            clearShapes() %>%
            addPolygons(layerId = geodata()$GEO_VALUE,
                        group = "Rates",
                        color = "#444444", 
                        weight = 0.25, smoothFactor = 0.5,
                        opacity = 1.0, fillOpacity = 0.0) %>%
            addPopupImages(myplots, group="Rates") %>%
            clearControls() %>% 
            addLegend("bottomleft",
                      pal = pal(),
                      values = ~rate_data()$OVERALL,
                      title = "Rate",
                      opacity = 0.6)
        
        # Uncomment this to allow toggling between panes
        # One issue is that if the Rates are unchecked and then checked again, the colors aren't restored
        # addLayersControl(overlayGroups = c("Place names", "Rates")) %>%
        # setView(lng=-118.3, lat=34.1, zoom=10) %>%
        # addLegend("bottomleft",
        #           pal = pal(),
        #           values = ~rate_data()$OVERALL,
        #           title = "Rate",
        #           opacity = 0.6)


    
    })
    
    # Add legend and color
    # Input dependencies: measure, geography, year
    observe({
        
        # Add legend
        delay(5, leafletProxy("map", data = geodata()) %>%
                  clearControls() %>%
                  addLegend("bottomleft",
                            pal = pal(),
                            values = ~rate_data()$OVERALL,
                            title = "Rate",
                            opacity = 0.6))
        
        # Add the proper shading
        pal_tmp <- pal()
        delay(10, js$changeColors(pal_tmp(rates())))

    })
    
    # Add color when rates change
    # (this bit is only useful for the animation)
    # Input dependencies: measure, geography, year
    observe({
        
        # Set color palette
        pal_tmp <- pal()

        # Custom written function
        js$changeColors(pal_tmp(rates()))
        
    })
    
})
