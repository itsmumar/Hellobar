function BarElement(props) {
  SiteElement.call(this, props);
};

BarElement.prototype = Object.create(SiteElement.prototype);
BarElement.prototype.constructor = BarElement;

BarElement.prototype.setupIFrame = function(iframe){
  SiteElement.prototype.setupIFrame.call(this, iframe);
  HB.addClass(iframe, "hb-" + this.size);
  HB.addClass(iframe, "hb-" + this.placement);
  HB.addClass(iframe, (HB.t(this.remains_at_top) ? " remains-in-place" : ""));

  if ( this.animated ) {
    HB.addClass(iframe, "hellobar");
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
    HB.p.id="hellobar-pusher";
    HB.p.className = "hb-" + this.size;
    // shrinks pusher if siteElement hidden by viewCondition rules
    if (HB.w.style.display === "none") {HB.p.style.height = 0};
    HB.injectAtTop(HB.p, this.placement == "bar-bottom");
  }
};

BarElement.prototype.prerender = function(){
  // Disable wiggle on Mobile Safari because it blocks the click action
  if(this.wiggle_button && !HB.isMobileSafari()) {
    this.wiggle = 'wiggle';
  } else {
    this.wiggle = '';
  }

  SiteElement.prototype.prerender.call(this);
};
