// IE 8 Support for initializers
if (!Object.create) {
    Object.create = function(o, properties) {
        if (typeof o !== 'object' && typeof o !== 'function') throw new TypeError('Object prototype may only be an Object: ' + o);
        else if (o === null) throw new Error("This browser's implementation of Object.create is a shim and doesn't support 'null' as the first argument.");
        if (typeof properties != 'undefined') throw new Error("This browser's implementation of Object.create is a shim and doesn't support a second argument.");
        function F() {}
        F.prototype = o;
        return new F();
    };
}

var SiteElement = function(props) {
  for (var key in props) {
    this[key] = props[key]
  }
};

SiteElement.prototype.setupIFrame = function(iframe) {
  if(this.animated) {
    HB.addClass(iframe, "hb-animated")
  }

  // Any view_condition including string 'intent' will run the intent event listeners
  if (this.view_condition.indexOf('intent') !== -1) {
    HB.initializeIntentListeners();
  };

  // Starts setIntervals that check display setting conditions
  HB.checkForDisplaySetting(this);
};

SiteElement.prototype.prerender = function(){
  HB.sanitize(this);
  if(HB.isIEXOrLess(9))
    this.animated = false;
};

SiteElement.prototype.imagePlacementClass = function() {
  if(!!this.image_url) {
    return 'image-' + this.image_placement
  } else {
    return ''
  }
}

SiteElement.prototype.imageFor = function(location) {
  if (!this.image_url || location.indexOf(this.image_placement) == -1)
    return "";
  else
    return "<div class='hb-image-wrapper " + this.image_placement + "'><img class='uploaded-image' src=" + this.image_url + " /></div>";
}
