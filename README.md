# KPSC-RAND Heart Disease Data Portal

## Introduction

The KPSC-RAND Heart Disease Data Portal, a collaboration between Kaiser Permanente Southern California (KPSC) and the RAND Corporation, is a web application that facilitates the exploration of hypertension prevalence rates in Los Angeles County. The portal can be viewed live at https://mappingportal.kp-scalresearch.org. For more information, see **<link to Kaiser landing page>**. 

This repository provides the code for the app and some supplementary files. It does not include actual hypertension data. However, a template file is included such that the app can be run for illustrative purposes.

## Usage

The Heart Disease Data Portal is an R Shiny web app. For more information about Shiny see [https://shiny.rstudio.com/](https://shiny.rstudio.com/).

To run the code in this repository:

1. Clone this repository to your computer. 
2. Launch R and navigate to the cloned repository.
3. Set up the project library by calling `renv::restore()`. This installs the packages necessary for running the app. For more information about renv see [https://rstudio.github.io/renv/articles/collaborating.html](https://rstudio.github.io/renv/articles/collaborating.html). 
4. Launch the app using `shiny::runApp()`.

## License

All code in this project is Copyright (C) The RAND Corporation, and is licensed under the GPL-v3.

## Contact

* Adam Scherling <ascherli@rand.org>
* Claudia Nau <Claudia.L.Nau@kp.org>
* Roland Sturm <sturm@rand.org>
* Ariadna Padilla <ariadna.padilla@kp.org>

