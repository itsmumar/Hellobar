// We use a variable called _hbq which is defined as just an empty array on the
// user's page in the embed script (ensuring that it is present). This allows users
// to push function calls into the _hbq array, e.g.:
//
//    _hbq.push(function(){alert('Hello Bar has loaded!');});
//
// Because _hbq is defined on the page this will never error out - even if the HB script
// fails to load. Once the HB script loads we replace the _hbq variable with a custom HBQ
// object that has its own push method. HBQ#push just immediately calls the action.
//

// When HBQ is initialized we also kickstart the initialization process of Hello Bar:
if (typeof(_hbq) === 'undefined') {
  _hbq = [];
}

var HBQ = function () {
  HB.isMobile = false;
  /* IF CHANGED, UPDATE SLIDER ELEMENT CSS */
  HB.mobilePreviewWidth = 250;

  // Need to load the serialized cookies
  HB.loadCookies();

  // Set tracking (uses hb_ignore query parameter)
  HB.setTracking(location.search);

  // Disable tracking if tracking is manually set to off
  if (HB.t(HB.gc('disableTracking'))) {
    HB_DNT = true;
  }

  var i;
  // Once initialized replace the existing data with it
  if (typeof(_hbq) != 'undefined' && _hbq && _hbq.length) {
    for (i = 0; i < _hbq.length; i++)
      this.push(_hbq[i]);
  }

  // Set all the default tracking trackings
  HB.setDefaultSegments();

  // HB is about to render elements, run client defined callback
  if (typeof HB_BEFORE === 'function')
    HB_BEFORE();

  HB.showSiteElements();

  // HB has finished, run any client defined callback
  if (typeof HB_READY === 'function')
    HB_READY();
}

// Call the function right away once this is loaded
HBQ.prototype.push = function () {
  if (arguments.length === 1 && typeof(arguments[0]) === 'function')
    (arguments[0])();
  else {
    var originalArgs = [];
    for (var i = 1; i < arguments.length; i++) {
      originalArgs.push(arguments[i]);
    }
    HB[arguments[0]].apply(HB, originalArgs);
  }
}
// Keep everything within the HB namespace
var HB = {
  // TODO check all usages of HB.CAP, change to base.capabilities
  CAP: {}, // Capabilies
  geoRequestInProgress: false,

  // TODO -> elements
  // Grabs site elements from valid rules and displays them
  showSiteElements: function () {
    var siteElements = [];
    // If a specific element has already been set, use it
    // Otherwise use the tradition apply rules method
    var siteElement = HB.getFixedSiteElement();
    if (siteElement)
      siteElements = [siteElement];
    else
      siteElements = HB.applyRules();
    for (var i = 0; i < siteElements.length; i++) {
      // TODO REFACTOR use createAndAddToPage
      HB.addToPage(HB.createSiteElement(siteElements[i]));
    }
  },



  // TODO this is inner for createClass
  // Copy functions from spec into klass
  cpFuncs: function (spec, klass) {
    for (var key in spec) {
      if (spec.hasOwnProperty(key)) {
        var value = spec[key];
        if (typeof(value) === 'function') {
          klass.prototype[key] = value;
        }
      }
    }
  },


  // TODO !!! Do we really need to maintain hierarchy of classes for bars?
  // Creates a class
  createClass: function (spec, superClass) {
    // Set up the initializer
    var klass = function () {
      // Call the initializer
      if (this.initialize) this.initialize.apply(this, arguments);
    }
    if (superClass) {
      // If we have a super class copy over all those methods
      HB.cpFuncs(superClass.prototype, klass);

      // Set up the superclass
      klass.superClass = superClass;

      // Also set up callSuper
      spec.callSuper = function (name) {
        this.constructor.superClass.prototype[name].apply(this, Array.prototype.slice.call(arguments, 1));
      }
    }

    // Copy over the specs
    HB.cpFuncs(spec, klass);

    return klass;
  },


  // Adds CSS to the page
  addCSS: function (css) {
    if (!css) {
      return;
    }
    if (!HB.css) {
      HB.css = '';
    }
    // Update CSS related to hellobar logo
    // TODO REFACTOR change HB_PS to site.secret()
    css = css.split('hellobar-logo-wrapper').join('hellobar-logo-wrapper_' + HB_PS);

    HB.css += '<style>' + css + '</style>';
  },


  // TODO this is called from html pieces. Should it be in tracking.hb module? or in elements.conversion?
  // Records the rule being formed when the visitor clicks the specified element
  trackClick: function (domElement, siteElement) {
    var url = domElement.href;
    HB.converted(siteElement, function () {
      if (domElement.target != '_blank') document.location = url;
    });
  },

  // TODO remove this. Already have this function in base.dom
  // Calls the specificied callback once the DOM is ready.
  /*domReady: function (callback) {
    // To save on script size we do the simplest possible thing which
    // is to loop until the body exists
    if (document.body)
      callback();
    else {
      var intervalID = setInterval(function () {
        if (document.body) {
          callback();
          clearInterval(intervalID);
        }
      }, 50);
    }
  },*/

  // TODO ???
  // If window.HB_element_id is set, use that to find the site element
  // Will return null if HB_element_id is not set or no site element exists with that id
  getFixedSiteElement: function () {
    if (window.HB_element_id != null) {
      for (i = 0; i < HB.rules.length; i++) {
        var rule = HB.rules[i];
        for (j = 0; j < rule.siteElements.length; j++) {
          var siteElement = rule.siteElements[j];
          if (siteElement.wordpress_bar_id === window.HB_element_id)
            return siteElement;
        }
      }
    }
    return null;
  },










  /*// TODO -> ???
  branding_template: function () {
    var stored = HB.gc('b_template');
    return stored != null ? stored : HB.CAP.b_variation;
  },*/




};
window.HB = HB;
