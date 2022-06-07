shinyjs.displayRates = function(params) {
    // pull parameters and define empty html for mouseout
    districts = params[0];
    newHTML = params[1];
    emptyHTML = '<div><style> .leaflet-control.rate-label { transform: translate(20px,-90px); position: fixed !important; left: 350; text-align: center; padding-left: 10px;  padding-right: 10px;  background: rgba(255,255,255,0.75); font-weight: bold; font-size: 24px; } </style>Mouse over a district to display rates</div>';
    
    // loop over each district and assign mouseover and mouseout functions
    for (i=0; i<districts.length; i++) {
      thisDistrict = districts[i];
      thisHTML = newHTML[i]
	    element = document.getElementsByClassName(thisDistrict);
	    
	    // if the district is currently highlighted, update the label
      if (highlightedDistrict==thisDistrict) {
        rateLabel = document.getElementsByClassName('rate-label');
	      rateLabel[0].innerHTML = thisHTML;
      }
	    
	    // on mouseover, add the label
	    element[0].onmouseover = ( function(new_html, currentDistrict) {
        return function() { 
          this.setAttribute('stroke-width', 4)
          this.parentNode.appendChild(this);
          highlightedDistrict = currentDistrict;
          rateLabel = document.getElementsByClassName('rate-label');
	        rateLabel[0].innerHTML = new_html;
        }
      }) (thisHTML, thisDistrict);
      
      // on mouseout, remove the label
      element[0].onmouseout = ( function(new_html) {
        return function() { 
          this.setAttribute('stroke-width', 1)
          highlightedDistrict = '';
          rateLabel = document.getElementsByClassName('rate-label');
	        rateLabel[0].innerHTML = new_html;
        }
      }) (emptyHTML);
      
    }
    
}
