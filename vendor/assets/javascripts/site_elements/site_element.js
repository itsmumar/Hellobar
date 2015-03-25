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

SiteElement.prototype.setupIFrame = function(){
  // Override this func
};

SiteElement.prototype.prerender = function(){
  HB.sanitize(this);
  if(HB.isIEXOrLess(9))
    this.animated = false;
};
