shinyjs.changeColors = function(params){
    districts = params[0];
    colors = params[1];
    for (i=0; i<districts.length; i++) {
      thisDistrict = districts[i];
	    element = document.getElementsByClassName(thisDistrict);
	    element[0].setAttribute('fill',colors[i]);
	    element[0].setAttribute('fill-opacity',0.6);
    }
}
