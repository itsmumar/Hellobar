function ModalElement(props) {
  SiteElement.call(this, props);
  this.link_color = "FFFFFF";
};

ModalElement.prototype = Object.create(SiteElement.prototype);
ModalElement.prototype.constructor = ModalElement;

ModalElement.prototype.setupIFrame = function(iframe){

  console.log("setting up a modal")
  console.log("view_condition is", this.view_condition);

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
