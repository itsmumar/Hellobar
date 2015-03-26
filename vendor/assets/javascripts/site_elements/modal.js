function ModalElement(props) {
  SiteElement.call(this, props);
  this.link_color = "FFFFFF";
};

ModalElement.prototype = Object.create(SiteElement.prototype);
ModalElement.prototype.constructor = ModalElement;

ModalElement.prototype.setupIFrame = function(iframe){
  if(this.animated) {
    HB.addClass(iframe, "animated")
  }
};
