function SliderElement(props) {
  SiteElement.call(this, props);
  this.link_color = "FFFFFF";
};

SliderElement.prototype = Object.create(SiteElement.prototype);
SliderElement.prototype.constructor = SliderElement;

SliderElement.prototype.setupIFrame = function(iframe){
  SiteElement.prototype.setupIFrame.call(this, iframe);

  HB.addClass(iframe, this.placement)

  if(this.animated) {
    HB.addClass(iframe, "animated")
  }
};
