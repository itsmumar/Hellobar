function ModalElement(props) {
  SiteElement.call(this, props);
  this.link_color = "FFFFFF";
};

ModalElement.prototype = Object.create(SiteElement.prototype);
ModalElement.prototype.constructor = ModalElement;

ModalElement.prototype.setupIFrame = function(iframe){

  console.log("setting up a modal")
  console.log("view_condition is", this.view_condition);

  if(this.animated) {
    HB.addClass(iframe, "animated")
  }
};
