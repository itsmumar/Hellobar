function TakeoverElement(props) {
  SiteElement.call(this, props);
};

TakeoverElement.prototype = Object.create(SiteElement.prototype);
TakeoverElement.prototype.constructor = TakeoverElement;

TakeoverElement.prototype.setupIFrame = function(iframe){
  if(this.animated) {
    HB.addClass(iframe, "animated")
  }
};