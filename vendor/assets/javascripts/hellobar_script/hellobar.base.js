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
  // Initialize the rules array so it can be pushed into
  HB.rules = [];
  HB.siteElementsOnPage = [];
  HB.isMobile = false;
  HB.maxSliderSize = 380;
  /* IF CHANGED, UPDATE SLIDER ELEMENT CSS */
  HB.mobilePreviewWidth = 250;
  HB.id_type_map = {
    'hellobar-bar': 'bar',
    'hellobar-modal': 'modal',
    'hellobar-slider': 'slider',
    'hellobar-takeover': 'takeover',
    'hellobar-custom': 'custom'
  }

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

  // Takes a hash (either visitor or siteElement) and
  // serializes it into a string
  // ADAPTER
  serializeCookieValues: function (hash) {
    return hellobar('base.serialization').serialize(hash);
  },

  // Called by parseCookies. Takes a string (either visitor or siteElement) and
  // parses it into a hash
  // ADAPTER
  parseCookieValues: function (string) {
    return hellobar('base.serialization').deserialize(string);
  },

  // TODO totally refactor this, get rid of globals
  // Loads the cookies from the browser cookies into global hash HB.cookies
  // in the format of {siteElements:{...}}, visitor:{...}}
  loadCookies: function () {
    // Don't let any cookies get set without a site ID
    if (typeof(HB_SITE_ID) === 'undefined')
      HB.cookies = {siteElements: {}, visitor: {}, location: {}};
    else {
      HB.cookies = {
        visitor: HB.parseCookieValues(HB.gc('hbv_' + HB_SITE_ID)),
        location: HB.parseCookieValues(HB.gc('hbglc_' + HB_SITE_ID)),
        siteElements: {}
      };
      // We need to parse out the nested site element data
      var siteElementData = (HB.gc('hbs_' + HB_SITE_ID) || '').split('^');
      for (var i = 0; i < siteElementData.length; i++) {
        var raw = siteElementData[i];
        if (raw) {
          var partIndex = raw.indexOf('|');
          var id = raw.slice(0, partIndex);
          var data = raw.slice(partIndex + 1);
          HB.cookies.siteElements[id] = HB.parseCookieValues(data);
        }
      }
    }
  },

  // TODO totally refactor this
  // Saves HB.cookies into the actual cookie
  saveCookies: function () {
    // Don't let any cookies get set without a site ID
    if (typeof(HB_SITE_ID) != 'undefined') {
      HB.sc('hbv_' + HB_SITE_ID, HB.serializeCookieValues(HB.cookies.visitor), 365 * 5);
      // We encode the site elements as:
      // site_element_id|data^site_element_id|data...
      var siteElementData = [];
      for (var k in HB.cookies.siteElements) {
        var value = HB.cookies.siteElements[k];
        if (typeof(value) != 'function') {
          siteElementData.push(k + '|' + HB.serializeCookieValues(value));
        }
      }
      HB.sc('hbs_' + HB_SITE_ID, siteElementData.join('^'), 365 * 5);
    }
  },

  // TODO -> visitorData or tracking.hb
  // Gets the visitor attribute specified by the key or returns null
  getVisitorData: function (key) {
    if (!key) {
      return null;
    }

    if (key.indexOf('gl_') !== -1) {
      return hellobar('geolocation').getGeolocationData(key, function(data, isCached) {
        if (isCached === false) {
          HB.loadCookies();
          HB.showSiteElements();
        }
      });
    }
    else {
      return HB.cookies.visitor[key];
    }
  },

  // TODO get rid of this public setter - is this possible? There many usages of this function
  // TODO ideally we need a separate module visitorData
  // Sets the visitor attribute specified by the key to the value in the HB.cookies hash
  // Also updates the cookies via HB.saveCookies
  setVisitorData: function (key, value, skipEmptyValue) {
    if (skipEmptyValue && !value) // This allows us to only conditionally set values
      return;
    HB.cookies.visitor[key] = value;
    HB.saveCookies();
  },

  // TODO where should it be moved?
  // Gets the siteElement attribute from HB.cookies specified by the siteElementID and key
  getSiteElementData: function (siteElementID, key) {
    if (!siteElementID)
      return;
    siteElementID = siteElementID + '';
    var s = HB.cookies.siteElements;
    if (!s[siteElementID])
      s[siteElementID] = {}
    return s[siteElementID][key];
  },


  // TODO where should it be moved?
  // Sets the siteElement attribute specified by the key and siteElementID to the value in HB.cookies
  // Also updates the cookies via HB.saveCookies
  setSiteElementData: function (siteElementID, key, value) {
    if (!siteElementID)
      return;
    siteElementID = siteElementID + '';
    var s = HB.cookies.siteElements;
    if (!s[siteElementID])
      s[siteElementID] = {}
    s[siteElementID][key] = value;
    HB.saveCookies();
  },

  // TODO -> visitorData (or call it visitor?) Visitor should be bars agnostic?
  // Returns the visitor's unique ID which should be a random value
  i: function () {
    var uuid;
    // Check if we have a cookie
    if (uuid = HB.gc('hbuid'))
      return uuid; // If so return that
    // Otherwise generate a new value
    var d = new Date().getTime();
    uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      var r = (d + Math.random() * 16) % 16 | 0;
      d = Math.floor(d / 16);
      return (c == 'x' ? r : (r & 0x7 | 0x8)).toString(16);
    });
    // Set it in the cookie
    HB.sc('hbuid', uuid, 5 * 365);

    // Return it
    return uuid;
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

  // TODO -> base.templating
  // A global variable to store templates
  templateHTML: {},

  // TODO refactor, generalize, make it work with base.templating
  brandingTemplates: {},
  contentUpgradeTemplates: {},






  /*// TODO -> ??? elements.templating or base.templating? generalize
  // Sets the branding HTML.
  setBrandingTemplate: function (type, html) {
    HB.brandingTemplates[type] = html;
  },

  // TODO -> ??? elements.templating or base.templating? generalize
  getBrandingTemplate: function (type) {
    return HB.brandingTemplates[type];
  },*/

  /*// TODO -> ??? contentUpgrades.templating or base.templating? generalize
  // Sets the content upgrade HTML.
  setContentUpgradeTemplate: function (type, html) {
    HB.contentUpgradeTemplates[type] = html;
  },

  // TODO -> ??? contentUpgrades.templating or base.templating? generalize
  getContentUpgradeTemplate: function (type) {
    return HB.contentUpgradeTemplates[type];
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

  // TODO -> elements.rules ????? (make it inner) (also have something to do with visitorData)
  // Gets the current segment value that will be compared to the conditions
  // value
  getSegmentValue: function (segmentName) {
    // Convert long names to short names
    if (segmentName === 'url')
      segmentName = 'pu';
    else if (segmentName === 'device')
      segmentName = 'dv';
    else if (segmentName === 'country')
      segmentName = 'co';
    else if (segmentName === 'referrer' || segmentName === 'referer')
      segmentName = 'rf';
    else if (segmentName === 'date')
      segmentName = 'dt';

    // All other segment names
    return HB.getVisitorData(segmentName);
  },



  // TODO -> ??? (this is called during script initialization)
  // This just sets the default segments/tracking data for the visitor
  // (such as when the suer visited, referrer, etc)
  setDefaultSegments: function () {
    var nowDate = new Date();
    var now = Math.round(nowDate.getTime() / 1000);
    var hour = 60 * 60;
    var day = 24 * hour;
    var newSession = 0;

    // Track first visit and most recent visit and time since
    // last visit
    if (!HB.getVisitorData('fv'))
      HB.setVisitorData('fv', now);
    // Get the previous visit
    var previousVisit = HB.getVisitorData('lv');

    // Set the time since the last visit as the number
    // of days
    if (previousVisit)
      HB.setVisitorData('ls', Math.round((now - previousVisit) / day));
    if (((now - previousVisit) / hour) > 1) {
      newSession = 1;
    }

    HB.setVisitorData('lv', now);

    // Set the life of the visitor in number of days
    HB.setVisitorData('lf', Math.round((now - HB.getVisitorData('fv')) / day));

    // Track number of visitor visits
    HB.setVisitorData('nv', (HB.getVisitorData('nv') || 0) + 1);

    // Track number of visitor sessions
    HB.setVisitorData('ns', (HB.getVisitorData('ns') || 0) + newSession);

    // Check for UTM params
    var params = HB.paramsFromString(document.location);

    HB.setVisitorData('ad_so', params['utm_source'], true);
    HB.setVisitorData('ad_ca', params['utm_campaign'], true);
    HB.setVisitorData('ad_me', params['utm_medium'], true);
    HB.setVisitorData('ad_co', params['utm_content'], true);
    HB.setVisitorData('ad_te', params['utm_term'], true);

    HB.setVisitorData('pq', params, true)

    // Set referrer if it is from a different domain (don't count internal referrers)
    if (document.referrer) {
      var tld = HB.getTLD().toLowerCase();
      // Check to ensure that the tld is not present in the
      var referrer = (document.referrer + '').replace(/.*?\:\/\//, '').replace(/www\./i, '').toLowerCase().substr(0, 150);
      var referrerDomain = referrer.replace(/(.*?)\/.*/, '$1');
      if (referrerDomain.indexOf(tld) == -1) {
        // This is an external referrer
        // Set the original referrer if not set
        if (!HB.getVisitorData('or'))
          HB.setVisitorData('or', referrer);
        // Set the full current referrer
        HB.setVisitorData('rf', referrer);
        // Set the referrer domain
        HB.setVisitorData('rd', referrerDomain);

        // Check for search terms
        var referrerParams = HB.paramsFromString(document.referer);
        // Check for search terms
        HB.setVisitorData('st', referrerParams['query'] || referrerParams['q'] || referrerParams['search'], true);
      }

      // Always set the previous page to the referrer
      HB.setVisitorData('pp', referrer);
    } else {
      // There is no referrer so set the 'rf' and 'rd' segments to blank
      HB.setVisitorData('rf', '');
      HB.setVisitorData('rd', '');
      HB.setVisitorData('pp', '');
    }
    // Set the page URL
    HB.setVisitorData('pu', HB.n(document.location + '', false));

    // Set the page path
    HB.setVisitorData('pup', HB.n(document.location.pathname, true));

    // Set the date
    HB.setVisitorData('dt', (HB.ymd(HB.nowInTimezone())));
    // Detect the device
    HB.setVisitorData('dv', HB.device());
  },

  // TODO this should be inner for setDefaultSegments
  paramsFromString: function (url) {
    var params = {};
    if (!url)
      return params;
    url += ''; // cast to string
    var query = url.indexOf('?') == -1 ? url : url.split('?')[1];
    if (!query)
      return params;
    var pairs = query.split('&');
    for (var i = 0; i < pairs.length; i++) {
      var key, value;
      var components = pairs[i].split('=');
      components[1] || (components[1] = ''); // default the key to an empty string

      // handle ASCII encoding
      var utf8bytes = unescape(encodeURIComponent(components[0]));
      var key = decodeURIComponent(escape(utf8bytes));

      var utf8bytes = unescape(encodeURIComponent(components[1]));
      var value = decodeURIComponent(escape(utf8bytes));

      params[key] = value;
    }
    return params;
  },



  // TODO this should be inner for setDefaultSegments
  // This code returns the root domain of the current site so "www.yahoo.co.jp" will return "yahoo.co.jp" and "blog.kissmetrics.com
  // will return kissmetrics.com. It does so by setting a cookie on each "part" until successful (first tries ".jp" then ".co.jp"
  // then "yahoo.co.jp"
  getTLD: function () {
    var i, h,
      wc = 'tld=ck',
      hostname = document.location.hostname.split('.');
    for (i = hostname.length - 1; i >= 0; i--) {
      h = hostname.slice(i).join('.');
      document.cookie = wc + ';domain=.' + h + ';';
      if (document.cookie.indexOf(wc) > -1) {
        document.cookie = wc.split('=')[0] + '=;domain=.' + h + ';expires=Thu, 01 Jan 1970 00:00:01 GMT;';
        return h;
      }
    }
    return document.location.hostname;
  },




    // Parses the zone and returns the offset in seconds. If it can
  // not be parsed returns null.
  // Valid formats for zone are:
  // "HHMM", "+HHMM", "-HHMM", "HH:MM", "+HH:MM and "-HH:MM".
  parseTimezone: function (zone) {
    if (!zone || typeof(zone) != 'string')
      return null;
    // Add + if missing +/-
    if (zone[0] != '+' && zone[0] != '-')
      zone = '+' + zone;
    if (zone.indexOf(':') == -1)
      zone = zone.slice(0, zone.length - 2) + ':' + zone.slice(zone.length - 2);
    if (!zone.match(/^[\+-]\d{1,2}:\d\d$/))
      return null;
    // Parse it
    var parts = zone.split(':');
    var signMultiplier = zone[0] == '+' ? 1 : -1;
    var hour = Math.abs(parseInt(parts[0], 10));
    var minute = parseInt(parts[1], 10);

    return ((hour * 60 * 60) + (minute * 60)) * signMultiplier;
  },


  // TODO used in setDefaultSegments and elements.rules
  // Returns a Date object adjusted to the timezone specified (if none is
  // specified we try to use HB_TZ - if that is not present we use the user
  // timezone. The timezone of the actual Date object wills till be the
  // user's timezone since this can not be changed, but it will be offset
  // by the correct hours and minutes of the zone passed in.
  // If no valid format is found we use the current user's timezone
  // You can also pass in the value "visitor" which will use the visitor's
  // timezone
  nowInTimezone: function (zone) {
    // If no zone is specified try the HB_TZ variable
    if (!zone && typeof(HB_TZ) == 'string')
      zone = HB_TZ;
    var zoneOffset = HB.parseTimezone(zone);
    if (zoneOffset === null)
      return new Date();
    var now = new Date();
    return new Date(now.getTime() + (now.getTimezoneOffset() * 60 * 1000) + (zoneOffset * 1000))
  },

  // TODO this is inner of setDefaultSegments
  ymd: function (date) {
    if (typeof date === 'undefined') date = new Date();
    var m = date.getMonth() + 1;
    return date.getFullYear() + '-' + this.zeropad(m) + '-' + this.zeropad(date.getDate());
  },

  // TODO this is inner of setDefaultSegments
  // Copied from zeropad.jquery.js
  zeropad: function (string, length) {
    // default to 2
    string = string.toString();
    if (typeof length === 'undefined' && string.length == 1) length = 2;
    length = length || string.length;
    return string.length >= length ? string : this.zeropad('0' + string, length);
  },



  // TODO -> base.dom ???? (it's actually about showing condition)
  // TODO rename payload (it's a function)
  // Runs a function if the visitor has scrolled to a given height.
  scrollTargetCheck: function (scrollTarget, payload) {
    // scrollTarget of "bottom" and "middle" are computed during check, in case page size changes;
    // scrollTarget also accepts distance from top in pixels

    if (scrollTarget === 'bottom') {
      // arbitrary 300 pixels subtracted from page height to assume visitor will not scroll through a footer
      scrollTarget = (document.body.scrollHeight - window.innerHeight - 300);
    }
    else if (scrollTarget === 'middle') {
      // triggers just before middle of page - feels right due to polling rate
      scrollTarget = ((document.body.scrollHeight - (window.innerHeight * 2)) / 2);
    }

    // first condition checks if visitor has scrolled.
    // second condition guards against pages too small to scroll, displays immediately.
    // window.pageYOffset is same as window.scrollY, but with better compatibility.
    if (window.pageYOffset >= scrollTarget || document.body.scrollHeight <= scrollTarget + window.innerHeight) {
      payload();
    }
  },




  /*// TODO -> ???
  branding_template: function () {
    var stored = HB.gc('b_template');
    return stored != null ? stored : HB.CAP.b_variation;
  },*/




  // TODO this is called during initialization
  // Sets the disableTracking cookie to true or false based on hb_ignore=
  setTracking: function (queryString) {
    if (queryString.match(/hb_ignore/i)) {
      var bool = !!queryString.match(/hb_ignore=true/i);
      HB.sc('disableTracking', bool, 5 * 365);
    }
  }

};
window.HB = HB;
