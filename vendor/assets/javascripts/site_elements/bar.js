function BarElement(props) {
  SiteElement.call(this, props);
};

BarElement.prototype = Object.create(SiteElement.prototype);
BarElement.prototype.constructor = BarElement;

BarElement.prototype.setupIFrame = function(iframe){
  HB.addClass(iframe, this.size)
  HB.addClass(iframe, (HB.t(this.remains_at_top) ? " remains_at_top" : ""))
  
  if(this.animated) {
    HB.addClass(iframe, "hellobar")
    HB.addClass(iframe, "animated")
  }

  iframe.scrolling = "no";
  iframe.setAttribute("frameBorder", 0) // IE 9 and less
  // Remove the pusher if it exists
  if ( HB.p )
    HB.p.parentNode.removeChild(HB.p);
  HB.p = null;
  // Create the pusher (which pushes the page down) if needed
  if ( HB.t(this.pushes_page_down) )
  {
    HB.p = document.createElement("div");
    HB.p.id="hellobar_pusher";
    HB.p.className = this.size;
    HB.injectAtTop(HB.p);
  }
};

BarElement.prototype.prerender = function(){
  this.wiggle = (this.wiggle_button ? 'wiggle' : '');
  SiteElement.prototype.prerender.call(this);
};
