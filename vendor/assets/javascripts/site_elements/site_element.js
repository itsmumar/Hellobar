var SiteElement = function(props) {
  for (var key in props) {
    this[key] = props[key]
  }
};

SiteElement.prototype.setupIFrame = function(){
  // Override this func
};

SiteElement.prototype.prerender = function(){
  HB.sanitize(this);
  if(HB.isIENineOrLess())
    this.animated = false;
};
