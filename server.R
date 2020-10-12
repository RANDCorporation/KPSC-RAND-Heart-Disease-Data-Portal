#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(dplyr)
library(glue)
library(htmltools)
library(kableExtra)
library(knitr) # for kable function
library(leaflet)
# library(leafpop)
library(magrittr)
library(readxl)
library(sf)
library(shiny)
library(shinyjs)
library(stringr)
library(tidyr)

# Define server logic
shinyServer(function(input, output) {
    options(shiny.reactlog = TRUE)
    
    # measChoices <- c("Hypertension", "Hypertension - controlled", "Hypertension - uncontrolled")
    # geoChoices <- c("Health District", "Census Designated Place")
    # # It is assumed that the same set of years is available for each measure/geography
    # measChoice1 <- measChoices[1]
    # geoChoice1 <- geoChoices[1]
    # yearChoices <- list.files(glue("data/Rates_v3/{measChoice1}/{geoChoice1}")) %>% as.numeric
    
    # Selectors
    output$measureControls <- renderUI({
        measChoices <- list.files("data/Rates_v3")
        tagList(
            selectInput("measure", "Measure", choices = measChoices, 
                        selected = ifelse(is.na(input$measure), measChoices[1], input$measure))
        )
    })
    
    output$geoControls <- renderUI({
        measChoice1 <- list.files("data/Rates_v3")[1]
        geoChoices <- list.files(glue("data/Rates_v3/{measChoice1}"))
        tagList(
            selectInput("geo", "Geography", choices = geoChoices, 
                        selected = ifelse(is.na(input$geo), geoChoices[1], input$geo))
        )
    })
    
    output$yearControls <- renderUI({
        measChoice1 <- list.files("data/Rates_v3")[1]
        geoChoice1 <- list.files(glue("data/Rates_v3/{measChoice1}"))[1]
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
        } else if (geo=="Census Tract") {
            gd <- st_read('data/geodata/CT2010_original_WGS84/CT2010_original_WGS84.shp')
            gd %<>% rename(GEO_VALUE = TRACTCE10) %>% arrange(GEO_VALUE)
        } else if (geo=="Census Designated Place") {
            gd <- st_read('data/geodata/CENSUS_DESIGNATED_PLACES_2010_WGS84/CENSUS_DESIGNATED_PLACES_2010_WGS84.shp')
            gd %<>% rename(GEO_VALUE = NAME) %>% arrange(GEO_VALUE)
        }
        
        # calculate centroids of each geographic unit (for placing popups)
        gd$centroid <- st_centroid(gd)$geometry
        
        return(gd)
    })
    
    # Read in data across all years
    rate_data <- reactive({
        geo_abb <- input$geo %>% gsub("[a-z]|\\s","",.)
        yearChoices <- list.files(glue("data/Rates_v3/{input$measure}/{input$geo}")) %>% as.numeric
        lapply(yearChoices, function(year) {
            read_excel(glue('data/Rates_v3/{input$measure}/{input$geo}/{year}/HBP_{geo_abb}_{year}.xlsx'))
        }) %>% Reduce(rbind, .)
    })
    
    # Create color palette
    pal <- reactive({colorBin(palette = "BuPu", domain = rate_data()$OVERALL, bins = 8)})
    
    # Create popup table
    get_popup_table <- reactive({
        geographies <- unique(as.character(geodata()$GEO_VALUE))
        df <- data.frame(YEAR=rate_data()$YEAR, 
                         GEO_VALUE=rate_data()$GEO_VALUE, 
                         OVERALL=rate_data()$OVERALL) 
        sapply(geographies, function(gg) {
            if (sum(df$GEO_VALUE==gg) > 0) {
                df %>% filter(GEO_VALUE==gg) %>% 
                    transmute(Year=YEAR, Rate=str_pad(round(OVERALL, 2), width=4, side='right', pad='0')) %>%
                    kable("html") %>% 
                    kable_styling(bootstrap_options = c("striped","condensed","responsive")) %>%
                    as.character %>% 
                    gsub('\n','',.)   
            } else {
                "No data"
            }
        })
    })
    
    # Get rates for the current year
    rates <- reactive({
        req(input$measure)
        req(input$year)
        req(input$geo)
        
        # Set parameters for determining which data to pull
        # year <- input$year
        # geo <- input$geo
        geo_abb <- input$geo %>% gsub("[a-z]|\\s","",.)
        
        # Read in the appropriate Excel file
        # rates_filepath <- glue('data/Rates_v3/Hypertension/{geo}/{year}/HBP_{geo_abb}_{year}.xlsx')
        # df <- read_excel(rates_filepath) %>% arrange(GEO_VALUE)
        df <- rate_data() %>% filter(YEAR==input$year)
        
        # Return values of the desired variable (currently OVERALL) in the same order as the geographies
        values <- df$OVERALL[match(geodata()$GEO_VALUE, df$GEO_VALUE)]
        return(values)
    })
    
    rates2 <- reactive({
        str_pad(round(rates(), 2), width=4, side='right', pad='0')
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

    # Set the initial map zoom
    # observe({
    #     leafletProxy("map", data = geodata()) %>%
    #         setView(lng=-118.3, lat=34.1, zoom=10)
    # }, once=TRUE)
    
    # Add polygons when geodata is loaded
    observe({

        # Set color palette
        #pal <- colorBin(palette = "BuPu", domain = rates(), bins = 8)
        
        # Get popup table
        popup_table <- get_popup_table()
        
        # add polygons
        leafletProxy("map", data = geodata()) %>%
            clearShapes() %>%
            clearControls() %>% 
            addPolygons(layerId = geodata()$GEO_VALUE,
                        group = "Rates",
                        color = "#444444", 
                        weight = 0.25, smoothFactor = 0.5,
                        opacity = 1.0, fillOpacity = 0.0,
                        popup = glue('<p><b>{geodata()$GEO_VALUE}</b>{popup_table}</p>')
                        # including a popup that depends on year breaks the animation...
                        # popup = glue('<p><b>{geodata()$GEO_VALUE}</b><br>{input$measure} rate ({input$year}): {rates2()}</p>')#,
                        #fillColor = ~pal(rates())
                        # highlightOptions = highlightOptions(color = "black",
                        #                                     weight = 2,
                        #                                     #fillColor = "white",
                        #                                     #fillOpacity = 1,
                        #                                     bringToFront = FALSE)
                        ) %>%
            # Uncomment this to allow toggling between panes
            # One issue is that if the Rates are unchecked and then checked again, the colors aren't restored
            # addLayersControl(overlayGroups = c("Place names", "Rates")) %>%
            # setView(lng=-118.3, lat=34.1, zoom=10) %>%
            addLegend("bottomleft",
                      pal = pal(),
                      values = ~rate_data()$OVERALL,
                      title = "Rate",
                      opacity = 1)
        
        pal_tmp <- pal()
        delay(5, js$changeColors(pal_tmp(rates())))
    
    })
    
    # Add color when rates change
    observe({
        
        # Set color palette
        # pal <- colorBin(palette = "BuPu", domain = rates(), bins = 8)
        pal_tmp <- pal()

        # Custom written function
        js$changeColors(pal_tmp(rates()))
        
        # # Clear polygons
        # js$clearPolygons()
        # 
        # # update map
        # leafletProxy("map", data = geodata()) %>%
        #     addPolygons(layerId = geodata()$GEO_VALUE,
        #                 group = "Rates",
        #                 color = "#444444", weight = 0.25, smoothFactor = 0.5,
        #                 opacity = 1.0, fillOpacity = 0.5,
        #                 fillColor = ~pal(rates()),
        #                 popup = ~htmlEscape(paste0(GEO_VALUE,': ',round(rates(),2))),
        #                 highlightOptions = highlightOptions(color = "black",
        #                                                     weight = 2,
        #                                                     #fillColor = "white",
        #                                                     #fillOpacity = 0,
        #                                                     bringToFront = TRUE))  %>%
        #     clearControls() %>%
        #     # Uncomment this (here and in geo-selection section) to allow toggling between panes
        #     #addLayersControl(overlayGroups = c("Place names", "Rates")) %>%
        #     addLegend("bottomleft",
        #               pal = pal,
        #               values = ~rates(),
        #               title = "Hypertension rate",
        #               opacity = 1)
        # 
        # # Remove old polygons
        # js$removePolygons()
        
    })
    
})
