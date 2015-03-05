function TakeoverElement(props) {
  SiteElement.call(this, props);
};

TakeoverElement.prototype = Object.create(SiteElement.prototype);
TakeoverElement.prototype.constructor = TakeoverElement;
