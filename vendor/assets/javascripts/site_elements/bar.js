function BarElement(props) {
  SiteElement.call(this, props);
};

BarElement.prototype = Object.create(SiteElement.prototype);
BarElement.prototype.constructor = BarElement;

BarElement.prototype.setupIFrame = function(iframe){
  SiteElement.prototype.setupIFrame.call(this, iframe);
  HB.addClass(iframe, this.size);
  HB.addClass(iframe, this.placement);
  HB.addClass(iframe, (HB.t(this.remains_at_top) ? " remains_in_place" : ""));

  if ( this.animated ) {
    HB.addClass(iframe, "hellobar");
    HB.addClass(iframe, "animated");
  }

  iframe.scrolling = "no";
  iframe.setAttribute("frameBorder", 0); // IE 9 and less

  // Remove the pusher if it exists
  if ( HB.p )
    HB.p.parentNode.removeChild(HB.p);

  HB.p = null;

  // Create the pusher (which pushes the page down) if needed
  if ( HB.t(this.pushes_page_down) ) {
    HB.p = document.createElement("div");
    HB.p.id="hellobar_pusher";
    HB.p.className = this.size;
    console.log("about to inject HB.p via bar.js");
    console.log(HB.p);
    HB.injectAtTop(HB.p, this.placement == "bar-bottom");
  }
};

BarElement.prototype.prerender = function(){
  this.wiggle = (this.wiggle_button ? 'wiggle' : '');
  SiteElement.prototype.prerender.call(this);
};
