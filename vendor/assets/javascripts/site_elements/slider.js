function SliderElement(props) {
  SiteElement.call(this, props);
  this.link_color = "FFFFFF";
};

SliderElement.prototype = Object.create(SiteElement.prototype);
SliderElement.prototype.constructor = SliderElement;

SliderElement.prototype.setupIFrame = function(iframe){
  HB.addClass(iframe, this.placement)

  // Any view_condition including string 'intent' will run the intent event listeners 
  if (this.view_condition.indexOf('intent') !== -1) { 
    HB.initializeIntentListeners(); 
  };

  if(this.animated) {
    HB.addClass(iframe, "animated")
  }

  // Starts setIntervals that check display setting conditions  
  HB.checkForDisplaySetting();
};
