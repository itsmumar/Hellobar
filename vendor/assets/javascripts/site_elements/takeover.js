function TakeoverElement(props) {
  SiteElement.call(this, props);
  this.link_color = "FFFFFF";
};

TakeoverElement.prototype = Object.create(SiteElement.prototype);
TakeoverElement.prototype.constructor = TakeoverElement;

TakeoverElement.prototype.setupIFrame = function(iframe){
  if(this.animated) {
    HB.addClass(iframe, "animated")
  }
};
