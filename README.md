# KPSC-RAND Heart Disease Data Portal

## Introduction

The KPSC-RAND Heart Disease Data Portal, a collaboration between Kaiser Permanente Southern California (KPSC) and the RAND Corporation, is a web application that facilitates the exploration of hypertension prevalence rates in Los Angeles County. The portal can be viewed live at [https://mappingportal.kp-scalresearch.org](https://mappingportal.kp-scalresearch.org). For more information, see [https://kp-scalresearch.org/heart-disease-mapping-portal/](https://kp-scalresearch.org/heart-disease-mapping-portal/). 

This repository provides the code for the app and some supplementary files. It does not include actual hypertension data. However, a template file is included such that the app can be run for illustrative purposes.

## Usage

The Heart Disease Data Portal is an R Shiny web app. For more information about Shiny see [https://shiny.rstudio.com/](https://shiny.rstudio.com/).

To run the code in this repository:

1. Clone this repository to your computer. 
2. Launch R and navigate to the cloned repository.
3. Set up the project library by calling `renv::restore()`. This installs the packages necessary for running the app. For more information about renv see [https://rstudio.github.io/renv/articles/collaborating.html](https://rstudio.github.io/renv/articles/collaborating.html). 
4. Launch the app using `shiny::runApp()`.

## Geographic data

The shapefiles used in this app were downloaded from the City of Los Angeles GeoHub here:
 - [Health Districts (2012)](https://geohub.lacity.org/datasets/421da90ceff246d08436a17b05818f45/explore?location=33.797083%2C-118.298809%2C9.00)
 - [Master Plan of Highways](https://geohub.lacity.org/datasets/a1543cfa466b45aab01d5ee75152ccb0/explore?location=34.260884%2C-118.302150%2C10.26)

## License

All code in this project is Copyright (C) The RAND Corporation, 2022, and is licensed under the GPL-v3.

## Contact

* Adam Scherling <ascherli@rand.org>
* Claudia Nau <Claudia.L.Nau@kp.org>
* Roland Sturm <sturm@rand.org>
* Ariadna Padilla <ariadna.padilla@kp.org>

