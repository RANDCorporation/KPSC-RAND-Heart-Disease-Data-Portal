shinyjs.changeYear = function(params){
    newYearHTML = params[0];
	  yearLabel = document.getElementsByClassName('year-label');
	  yearLabel[0].innerHTML = newYearHTML;
}
