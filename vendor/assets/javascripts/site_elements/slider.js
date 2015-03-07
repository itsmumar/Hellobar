function SliderElement(props) {
  SiteElement.call(this, props);
};

SliderElement.prototype = Object.create(SiteElement.prototype);
SliderElement.prototype.constructor = SliderElement;

SliderElement.prototype.setupIFrame = function(iframe){
  HB.addClass(iframe, this.slider_placement)
  
  if(this.animated) {
    HB.addClass(iframe, "animated")
  }
};