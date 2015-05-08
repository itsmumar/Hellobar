function TakeoverElement(props) {
  SiteElement.call(this, props);
  this.link_color = "FFFFFF";
};

TakeoverElement.prototype = Object.create(SiteElement.prototype);
TakeoverElement.prototype.constructor = TakeoverElement;

TakeoverElement.prototype.setupIFrame = function(iframe){

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
