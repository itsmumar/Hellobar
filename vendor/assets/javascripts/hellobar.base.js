// We use a variable called _hbq which is defined as just an empty array on the
// user's page in the embed script (ensuring that it is present). This allows users
// to push function calls into the _hbq array, e.g.:
//
//    _hbq.push(function(){alert("Hello Bar has loaded!");});
//
// Because _hbq is defined on the page this will never error out - even if the HB script
// fails to load. Once the HB script loads we replace the _hbq variable with a custom HBQ
// object that has its own push method. HBQ#push just immediately calls the action.
//

// When HBQ is initialized we also kickstart the initialization process of Hello Bar:
if ( typeof(_hbq) == 'undefined' ){ _hbq=[]; }

var HBQ = function()
{
  // Initialize the rules array so it can be pushed into
  HB.rules = [];
  HB.siteElementsOnPage = [];
  HB.isMobile = false;
  HB.maxSliderSize = 380; /* IF CHANGED, UPDATE SLIDER ELEMENT CSS */
  HB.mobilePreviewWidth = 250;
  HB.id_type_map = {
    "hellobar-bar": "bar",
    "hellobar-modal": "modal",
    "hellobar-slider": "slider",
    "hellobar-takeover": "takeover"
  }

  // Need to load the serialized cookies
  HB.loadCookies();

  // Set tracking (uses hb_ignore query parameter)
  HB.setTracking(location.search);

  // Disable tracking if tracking is manually set to off
  if (HB.t(HB.gc("disableTracking"))) {
    HB_DNT = true;
  }

  var i;
  // Once initialized replace the existing data with it
  if ( typeof(_hbq) != "undefined" && _hbq && _hbq.length ) {
    for (i=0; i<_hbq.length; i++ )
      this.push(_hbq[i]);
  }

  // Set all the default tracking trackings
  HB.setDefaultSegments();

  HB.showSiteElements();

  // HB has finished, run any client defined callback
  if(typeof HB_READY === 'function')
    HB_READY();
}

// Call the function right away once this is loaded
HBQ.prototype.push = function()
{
  if ( arguments.length == 1 && typeof(arguments[0]) == "function" )
    (arguments[0])();
  else
  {
    var originalArgs = [];
    for(var i=1;i<arguments.length;i++)
    {
      originalArgs.push(arguments[i]);
    }
    HB[arguments[0]].apply(HB, originalArgs);
  }
}
// Keep everything within the HB namespace
var HB = {
  CAP: {}, // Capabilies
  geoRequestInProgress: false,

  getLocation: function() {
    return window.location;
  },

  scriptIsInstalledProperly: function() {
    // return true when viewing in preview pane
    if (HB.CAP.preview)
      return true;

    var hostname = HB.getLocation().hostname;

    if (HB.isIpAddress(hostname) || hostname === "localhost")
      return true;

    return HB.n(hostname) === HB.n(window.HB_SITE_URL);
  },

  // Grabs site elements from valid rules and displays them
  showSiteElements: function() {
    var siteElements = [];
    // If a specific element has already been set, use it
    // Otherwise use the tradition apply rules method
    var siteElement = HB.getFixedSiteElement();
    if ( siteElement )
      siteElements = [siteElement];
    else
      siteElements = HB.applyRules();
    for(i=0; i < siteElements.length; i++ )
    {
      HB.addToPage(HB.createSiteElement(siteElements[i]));
    }
  },

  // Copy functions from spec into klass
  cpFuncs: function(spec, klass)
  {
    for (var key in spec)
    {
      if (spec.hasOwnProperty(key) )
      {
        var value = spec[key];
        if ( typeof(value) == "function" )
        {
          klass.prototype[key] = value;
        }
      }
    }
  },

  // Creates a class
  createClass: function(spec, superClass)
  {
    // Set up the initializer
    var klass = function()
    {
      // Call the initializer
      if ( this.initialize) this.initialize.apply(this, arguments);
    }
    if ( superClass )
    {
      // If we have a super class copy over all those methods
      HB.cpFuncs(superClass.prototype, klass);

      // Set up the superclass
      klass.superClass = superClass;

      // Also set up callSuper
      spec.callSuper = function(name)
      {
        this.constructor.superClass.prototype[name].apply(this, Array.prototype.slice.call(arguments, 1));
      }
    }

    // Copy over the specs
    HB.cpFuncs(spec, klass);

    return klass;
  },

  // Returns the element or looks it up via getElementById
  $: function(idOrElement)
  {
    if ( typeof(idOrElement) == "string" )
      return document.getElementById(idOrElement.replace("#",""));
    else
      return idOrElement;
  },

  // Returns whether or not a setting is true (treats "false" and string "0" as the boolean false)
  t: function(value)
  {
    return (value && value != "false" && value != "0") ? true : false;
  },

  currentURL: function()
  {
    return window.location.href;
  },

  isExternalURL: function(url)
  {
    var regex = /https?:\/\/((?:[\w\d]+\.)+[\w\d]{2,})/i;
    return regex.exec(HB.currentURL())[1] !== regex.exec(url)[1];
  },

  // Adds the CSS class to the target element
  addClass: function(element, className)
  {
    element = HB.$(element);
    if (element.className.indexOf(className) < 0) {
      element.className += " "+className;
    }
  },

  // Remove the CSS class name from the element
  removeClass: function(element, className)
  {
    element = HB.$(element);
    // Get all the CSS class names and then add them
    // back by building a new array minus the target CSS class name
    var classNames = element.className.split(" ");
    var newClassNames = [];
    for(var i=0;i<classNames.length;i++)
    {
      if ( classNames[i] != className )
        newClassNames.push(classNames[i]);
    }
    element.className = newClassNames.join(" ");
  },

  // Adds CSS to the page
  addCSS: function(css)
  {
    if ( !css ) return;
    if ( !HB.css )
      HB.css = "";
    // Update CSS related to hellobar logo
    css = css.split("hellobar-logo-wrapper").join("hellobar-logo-wrapper_"+HB_PS);

    HB.css += "<style>"+css+"</style>";
  },

  // Takes a URL and returns normalized domain (downcase and strip www)
  getNDomain: function(url)
  {
    if ( !url )
      return "";
    url = url+"";
    if ( url.indexOf("/") == 0 )
      return "";
    return url.replace(/.*?\:\/\//,"").replace(/(.*?)\/.*/,"$1").replace(/www\./i,"").toLowerCase();
  },

  // Normalizes a URL so that "https://www.google.com/#foo" becomes "http://google.com"
  // Also sorts the params alphabetically
  n: function(url, pathOnly)
  {
    url = (url+"").toLowerCase();
    // Add trailing slash when we think it's needed
    if ( url.match(/^https?:\/\/[^\/?]*$/i) ||
        url.match(/^[^\/]*\.(com|edu|gov|us|net|io)$/i))
      url += "/";

    //normalize query string to start with slash
    url = url.replace(/([^\/])\?/, "$1/?")

    // Get rid of things that make no difference in the URL (such as protocol and anchor)
    url = url.
      replace(/https?:\/\//,"").
      replace(/^www\./,"").
      replace(/\#.*/,"");

    // Strip the host if pathOnly
    if ( pathOnly )
    {
      // Unless it starts with a slash
      if ( !url.match(/^\//) )
          url = url.replace(/.*?\//, "/");
    }

    if ( url == "/" || url == "/?")
      return url;

    // If no query string just return the URL
    if ( url.indexOf("?") === -1 )
      return HB.stripTrailingSlash(url);

    // Get the params
    var urlParts = url.split("?");

    // If no params just return the URL with ?
    if ( !urlParts[1] )
      return HB.stripTrailingSlash(urlParts[0]) + "?";

    // Sort the params
    var sortedParams = urlParts[1].split("&").sort().join("&");
    return HB.stripTrailingSlash(urlParts[0] + "/") + "?" + sortedParams;
  },

  stripTrailingSlash: function(urlPart) {
    return urlPart.replace(/(.+)\/$/i, "$1");
  },

  // Returns true if the specified url matches the source pattern
  umatch: function(srcPattern, url)
  {
    if ( srcPattern.indexOf("?") == -1 ) // srcPattern does not have any query params...
      return HB.n(srcPattern, true) == HB.n(url, true).split("?")[0]; // ...so ignore them in the url
    // Otherwise URLs must match exactly
    return HB.n(srcPattern, true) == HB.n(url, true);
  },

  getVisitorAttributes: function()
  {
    // Ignore first and last view timestamps and email and social conversions
    var ignoredAttributes = "fv lv ec sc dt";
    // Ignore first and last converted timestamps and number of traffic conversions
    var ignoredAttributePattern = /(^ec.*_[fl]$)|(^sc.*_[fl]$)|(^l\-.+)/
    var attributes = {};
    // Remove ignored attributes
    for(var k in HB.cookies.visitor)
    {
      var value = HB.cookies.visitor[k];
      if ( (typeof(value) == 'string' || typeof(value) == 'number' || typeof(value) == 'boolean') && ignoredAttributes.indexOf(k) == -1 && !k.match(ignoredAttributePattern))
      {
        attributes[k.toLowerCase()] = (HB.cookies.visitor[k]+"").toLowerCase().substr(0,150);
      }
    }
    return HB.serializeCookieValues(attributes);
  },

  // Sends data to the tracking server (e.g. which siteElements viewed, if a rule was performed, etc)
  s: function(path, itemID, params, callback)
  {
    // If we are not tracking or this or no site ID then just issue the
    // callback without sending any data
    if ( typeof(HB_DNT) != "undefined" || typeof(HB_SITE_ID) == "undefined" || typeof(HB_WK) == "undefined")
    {
      if ( callback && typeof(callback) == "function" )
        callback();
      return;
    }
    // Build the URL
    var url = "/"+path+"/"+HB.obfID(HB_SITE_ID);
    if ( itemID )
      url += "/"+HB.obfID(itemID);
    var now = Math.round(new Date().getTime()/1000)

    params["t"] = now; // Timestamp
    params["v"] = HB.i(); // visitor UUID
    params["f"] = "i" // Make sure we return an image

    // Sign the URL
    params["s"] = HB.signature(HB_WK, url, params);

    // Add the query string
    url += "?" + HB.paramsToString(params);

    var img = document.createElement('img');
    img.style.display = 'none';
    if ( callback )
    {
      // Make sure you only call the callback once
      var issuedCallback = false;
      var issueCallback = function(){
        if( !issuedCallback)
          callback();
        issuedCallback = true;
      };
      // Call the callback within a set period of time in case the image
      // does not load
      setTimeout(issueCallback, 750);
      img.onload = issueCallback;
    }
    img.src = HB.hi(url);
  },

  // Returns the URL for the backend server (e.g. "hi.hellobar.com").
  hi: function(url)
  {
    return (document.location.protocol == "https:" ? "https" : "http")+ "://"+HB_BACKEND_HOST+url;
  },

  // Recoards the rule being formed when the visitor clicks the specified element
  trackClick: function(domElement, siteElement)
  {
    var url = domElement.href;
    HB.converted(siteElement, function(){if(domElement.target != "_blank") document.location = url;});
  },

  // Returns the conversion key used in the cookies to determine if this
  // conversion has already happened or not
  getConversionKey: function(siteElement)
  {
    switch(siteElement.subtype)
    {
      case "email":
        return "ec";
      case "social":
        return "sc";
      case "traffic":
        // Need to make sure this is unique per URL
        // getShortestKey returns either the raw URL or
        // a SHA1 hash of the URL - whichever is shorter
        return "l-"+HB.getShortestKeyForURL(siteElement.settings.url);
      // -------------------------------------------------------
      // IMPORTANT - if you add other conversion keys you need to
      // update the ignoredAttributePattern in getVisitorAttributes
    }
  },

  // Returns the shortest possible key for the given URL,
  // which may be a SHA1 hash of the url
  getShortestKeyForURL: function(url)
  {
    // If the URL is a path already or it's on the same domain
    // strip to just the path
    if ( url.indexOf("/") == 0 || HB.getNDomain(url) == HB.getNDomain(document.location) )
      url = HB.n(url, true);
    else
      url = HB.n(url); // Get full URL
    // If the URL is shorter than 40 chars just return it
    if  (url.length > 40 )
      return HBCrypto.SHA1(url).toString()
    else
      return url;
    // Otherwise return a SHA1 hash of the URL
  },

  // Called when a conversion happens (e.g. link clicked, email form filled out)
  converted: function(siteElement, callback)
  {
    var conversionKey = HB.getConversionKey(siteElement);
    var now = Math.round(new Date().getTime()/1000);
    var conversionCount = (HB.getVisitorData(conversionKey) || 0 ) + 1;

    // Set the number of conversions for the visitor for this type of conversion
    HB.setVisitorData(conversionKey, conversionCount);
    // Record first time converted, unless already set for the visitor for this type of conversion
    HB.setVisitorData(conversionKey+"_f", now);
    // Record last time converted for the visitor for this type of conversion
    HB.setVisitorData(conversionKey+"_l", now);

    // Set the number of conversions for the specific site element
    HB.setSiteElementData(siteElement.id, "nc", (HB.getSiteElementData(siteElement.id, "nc") || 0)+1);
    // Set the first time converted for the site element if not set
    if ( !HB.getSiteElementData(siteElement.id, "fc") )
      HB.setSiteElementData(siteElement.id, "fc", now);
    // Set the last time converted for the site element to now
    HB.setSiteElementData(siteElement.id, "lc", now);
    // Trigger the event
    HB.trigger("conversion", siteElement);
    // Send the data to the backend if this is the first conversion
    if(conversionCount == 1)
      HB.s("g", siteElement.id, {a:HB.getVisitorAttributes()}, callback);
    else if(typeof(callback) === typeof(Function))
      callback();
  },

  // Returns true if the visitor did this conversion or not
  didConvert: function(siteElement)
  {
    return HB.getVisitorData(HB.getConversionKey(siteElement));
  },

  // Returns true if the visitor previously closed a site element
  didDismissHB: function() {
    return HB.gc("HBDismissed") != null;
  },

  // Returns true if the visitor previously closed this particular site element
  didDismissThisHB: function(se) {
    var cookie_name = (se.type == "Takeover" || se.type == "Modal") ? "HBDismissedModals" : "HBDismissedBars";
    var cookie_str = HB.gc(cookie_name);
    if (cookie_str != undefined) {
      return JSON.parse(cookie_str).indexOf(se.id) >= 0;
    }
    return false;
  },

  // This takes the the email field, name field, and target siteElement DOM element.
  // It then checks the validity of the fields and if valid it records the
  // email and then sets the message in the siteElement to "Thank you". If invalid it
  // shakes the email field
  submitEmail: function(siteElement, emailField, nameField, targetSiteElement, thankYouText, redirect, redirectUrl)
  {
    HB.validateEmail(
      emailField.value,
      nameField.value,
      function(){
        var doRedirect = HB.t(redirect);
        var removeElements;
        var siteElementDoc = siteElement.w.contentDocument;

        if(!doRedirect) {
          if(targetSiteElement != null) {
            if(siteElement.use_free_email_default_msg) {
              // Hijack the submit button and turn it into a link
              var btnElement = siteElementDoc.getElementsByClassName('hb-cta')[0];
              var linkUrl = 'http://www.hellobar.com?hbt=emailSubmittedLink&sid=' + HB_SITE_ID;
              btnElement.textContent = 'Click Here';
              btnElement.href = linkUrl;
              btnElement.setAttribute('target', '_parent');
              btnElement.onclick = null;

              // Remove the email inputs and subtext
              removeElements = siteElementDoc.querySelectorAll('.hb-input-block, .hb-secondary-text');
            } else {
              // Remove the entire email input wrapper including the button
              removeElements = siteElementDoc.querySelectorAll('.hb-input-wrapper, .hb-secondary-text');
            }
            targetSiteElement.innerHTML='<span>' + thankYouText + '</span>';
          }

          if(removeElements != null) {
            for (var i = 0; i < removeElements.length; i++) {
              HB.hideElement(removeElements[i]);
            }
          }
        }

        HB.recordEmail(siteElement, emailField.value, nameField.value, function(){
          // Successfully saved
        });

        if(doRedirect) {
          window.location.href = redirectUrl;
        }
      },
      function(){
        // Fail
        HB.shake(emailField);
      }
    );
    return false;
  },

  // Called to validate the email and name. Does not actually submit the email
  validateEmail: function(email, name, successCallback, failCallback)
  {
    if ( email && email.match(/.+@.+\..+/) && !email.match(/,/))
      successCallback();
    else
      failCallback();
  },

  // Called to record an email for the rule without validation (also used by submitEmail)
  recordEmail: function(siteElement, email, name, callback)
  {
    if ( email )
    {
      var emailAndName = email;
      if ( name )
        emailAndName += ","+name;

      // Record the email address to the cnact list and then track that the rule was performed
      HB.s("c", siteElement.contact_list_id, {e:emailAndName}, function(){HB.converted(this.siteElement, callback)}.bind({siteElement: siteElement}));
    }
  },

  // Takes a hash (either visitor or siteElement) and
  // serializes it into a string
  serializeCookieValues: function(hash)
  {
    if ( !hash )
      return "";
    var pairs = [];
    for(var key in hash)
    {
      var value = hash[key];
      if (typeof(value) != "function" && typeof(value) != "object")
      {
        // Key can not contain ":", but value can
        pairs.push(HB.sanitizeCookieValue(key).replace(/:/g,"-")+":"+HB.sanitizeCookieValue(value));
      }
    }
    return pairs.join("|");
  },

  // Replaces all chars used within the serialization schema with a space
  sanitizeCookieValue: function(value)
  {
    return (value+"").replace(/[\^\|\,\;\n\r]/g, " ");
  },

  // Called by parseCookies. Takes a string (either visitor or siteElement) and
  // parses it into a hash
  parseCookieValues: function(string)
  {
    if ( !string )
      return {};
    var pairs = string.split("|");
    var results = {};
    for(var i=0;i<pairs.length;i++)
    {
      var data = pairs[i].split(":");
      var key = data[0];
      var value = data.slice(1,data.length).join(":");

      results[key] = HB.parseValue(value);
    }
    return results;
  },

  // Convert value to a number if it makes sense
  parseValue: function(value)
  {
    if ( parseInt(value, 10) == value )
      value = parseInt(value,10);
    else if ( parseFloat(value) == value )
      value = parseFloat(value);
    return value;
  },

  // Loads the cookies from the browser cookies into global hash HB.cookies
  // in the format of {siteElements:{...}}, visitor:{...}}
  loadCookies: function()
  {
    // Don't let any cookies get set without a site ID
    if ( typeof(HB_SITE_ID) == "undefined")
      HB.cookies = {siteElements:{}, visitor:{}, location:{}};
    else
    {
      HB.cookies = {
        visitor: HB.parseCookieValues(HB.gc("hbv_"+HB_SITE_ID)),
        location: HB.parseCookieValues(HB.gc("hbglc_"+HB_SITE_ID)),
        siteElements: {}
      };
      // We need to parse out the nested site element data
      var siteElementData = (HB.gc("hbs_"+HB_SITE_ID)||"").split("^");
      for(var i=0;i<siteElementData.length;i++)
      {
        var raw = siteElementData[i];
        if ( raw )
        {
          var partIndex = raw.indexOf("|");
          var id = raw.slice(0,partIndex);
          var data = raw.slice(partIndex+1);
          HB.cookies.siteElements[id] = HB.parseCookieValues(data);
        }
      }
    }
  },

  // Saves HB.cookies into the actual cookie
  saveCookies: function()
  {
    // Don't let any cookies get set without a site ID
    if ( typeof(HB_SITE_ID) != "undefined")
    {
      HB.sc("hbv_"+HB_SITE_ID, HB.serializeCookieValues(HB.cookies.visitor), 365*5);
      // We encode the site elements as:
      // site_element_id|data^site_element_id|data...
      var siteElementData = [];
      for(var k in HB.cookies.siteElements)
      {
        var value = HB.cookies.siteElements[k];
        if (typeof(value) != "function" )
        {
          siteElementData.push(k+"|"+HB.serializeCookieValues(value));
        }
      }
      HB.sc("hbs_"+HB_SITE_ID, siteElementData.join("^"), 365*5);
    }
  },

  // Gets the visitor attribute specified by the key or returns null
  getVisitorData: function(key)
  {
    if (key == undefined) return null;

    if (key.indexOf("gl_") != -1) {
      return HB.getGeolocationData(key);
    }
    else
    {
      return HB.cookies.visitor[key];
    }
  },

  // Sets the visitor attribute specified by the key to the value in the HB.cookies hash
  // Also updates the cookies via HB.saveCookies
  setVisitorData: function(key, value, skipEmptyValue)
  {
    if ( skipEmptyValue && !value) // This allows us to only conditionally set values
      return;
    HB.cookies.visitor[key] = value;
    HB.saveCookies();
  },

  // Gets the siteElement attribute from HB.cookies specified by the siteElementID and key
  getSiteElementData: function(siteElementID, key)
  {
    if ( !siteElementID )
      return;
    siteElementID = siteElementID+"";
    var s = HB.cookies.siteElements;
    if ( !s[siteElementID] )
      s[siteElementID] = {}
    return s[siteElementID][key];
  },

  // Sets the siteElement attribute specified by the key and siteElementID to the value in HB.cookies
  // Also updates the cookies via HB.saveCookies
  setSiteElementData: function(siteElementID, key, value)
  {
    if ( !siteElementID )
      return;
    siteElementID = siteElementID+"";
    var s = HB.cookies.siteElements;
    if ( !s[siteElementID] )
      s[siteElementID] = {}
    s[siteElementID][key] = value;
    HB.saveCookies();
  },

  // gets data from local storage
  getLocalStorageData: function(name)
  {
    localData = window.localStorage.getItem(name);
    if (localData != null) {
      parsedData = JSON.parse(localData);

      expDate = new Date(parsedData.expiration);
      today = new Date;
      if (today > expDate){
        window.localStorage.removeItem(name);
        return null;
      } else {
        return parsedData.value;
      }
    } else {
      return null;
    }
  },

  // Gets a cookie
  gc: function(name)
  {
    localValue = HB.getLocalStorageData(name);
    if (localValue != null) {
      return unescape(localValue);
    } else {
      var i,x,y,c=document.cookie.split(";");
      for (i=0;i<c.length;i++)
      {
        x=c[i].substr(0,c[i].indexOf("="));
        y=c[i].substr(c[i].indexOf("=")+1);
        x=x.replace(/^\s+|\s+$/g,"");
        if (x==name)
        {
          document.cookie = name + "=; expires=Thu, 01 Jan 1970 00:00:01 GMT;";
          HB.sc(name, y)
          return unescape(y);
        }
      }
    }
  },

  // Sets a cookie
  // exdays can be number of days or a date object
  sc: function(name,value,exdays,path)
  {
    if ( typeof(HB_NC) != "undefined" )
      {
        return;
      } else {
        var exdate= typeof exdays == "object" ? exdays : new Date();
        if(typeof exdays == "number")
          exdate.setDate(exdate.getDate() + exdays);

        var dataToSave = {};
        dataToSave.value = value;
        dataToSave.expiration = exdate;
        window.localStorage.setItem(name, JSON.stringify(dataToSave));
      }
  },

  // Returns the visitor's unique ID which should be a random value
  i: function()
  {
    var uuid;
    // Check if we have a cookie
    if ( uuid = HB.gc("hbuid") )
      return uuid; // If so return that
    // Otherwise generate a new value
    var d = new Date().getTime();
    uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = (d + Math.random()*16)%16 | 0;
      d = Math.floor(d/16);
      return (c=='x' ? r : (r&0x7|0x8)).toString(16);
    });
    // Set it in the cookie
    HB.sc("hbuid", uuid, 5*365);

    // Return it
    return uuid;
  },

  // Calls the specificied callback once the DOM is ready.
  domReady: function(callback)
  {
    // To save on script size we do the simplest possible thing which
    // is to loop until the body exists
    if ( document.body )
      callback();
    else
    {
      var intervalID = setInterval(function(){
        if ( document.body )
        {
          callback();
          clearInterval(intervalID);
        }
      }, 50);
    }
  },

  // A global variable to store templates
  templateHTML: {},
  brandingTemplates: {},

  // Sets the template HTML. Note if you override getTemplate this will have
  // no affect
  setTemplate: function(type, html)
  {
    HB.templateHTML[type] = html;
  },

  // Returns the template HTML for the given siteElement. Most of the time the same
  // template will be returned for the same siteElement. The values in {{}} are replaced with
  // the values from the siteElement
  //
  // By default this just returns the HB.templateHTML variable for the given rule type
  getTemplate: function(siteElement)
  {
    return HB.templateHTML[siteElement.template_name];
  },

  // Sets the branding HTML.
  setBrandingTemplate: function(type, html)
  {
    HB.brandingTemplates[type] = html;
  },

  getBrandingTemplate: function(type)
  {
    return HB.brandingTemplates[type];
  },

  // Takes each string value in the siteElement and escapes HTML < > chars
  // with the matching symbol
  sanitize: function(siteElement){
    for (var k in siteElement){
      if (siteElement.hasOwnProperty(k) && siteElement[k]) {
        if (siteElement[k].replace) {
          siteElement[k] = siteElement[k].replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g, '&quot;');
        } else if(!Array.isArray(siteElement[k])) {
          siteElement[k] = HB.sanitize(siteElement[k]);
        }
      }
    }
    return siteElement;
  },

  isIE11: function() {
    var myNav = navigator.userAgent.toLowerCase();
    return myNav.indexOf('rv:11') != -1;
  },

  isIEXOrLess: function(x) {
    var myNav = navigator.userAgent.toLowerCase();
    var version = (myNav.indexOf('msie') != -1) ? parseInt(myNav.split('msie')[1]) : false;

    if(isNaN(version) || version == null || version == false)
      return false;

    if (version <= x)
      return true;
  },

  // Returns true if the device is using mobile safari (ie, ipad / iphone)
  isMobileSafari: function() {
    var ua = navigator.userAgent.toLowerCase();
    return (ua.indexOf("safari") > -1 && (ua.indexOf("iphone") > -1 || ua.indexOf("ipad") > -1));
  },

  // Renders the html template for the siteElement by calling HB.parseTemplateVar for
  // each {{...}} entry in the template
  renderTemplate: function(html, siteElement)
  {
    return html.replace(/\{\{(.*?)\}\}/g, function(match, value){
      return HB.parseTemplateVar(value, siteElement);
    });
  },

  // Parses the value passed in in {{...}} for a template (which basically does an eval on it)
  parseTemplateVar: function(value, siteElement)
  {
    try{value = eval(value)}catch(e){}
    if ( value === undefined || value === null )
      return "";
    return value;
  },

  // This lets users set a callback for a Hello Bar event specified by eventName (e.g. "siteElementshown")
  on: function(eventName, callback)
  {
    if (!HB.eventCallbacks)
      HB.eventCallbacks = {};
    if ( !HB.eventCallbacks[eventName] )
      HB.eventCallbacks[eventName] = [];
    HB.eventCallbacks[eventName].push(callback);
  },

  // This is called internally to trigger a Hello Bar event (e.g. "siteElementshown")
  // Although it may look like no arguments are passed to trigger that is not true.
  // The first argument is the event name and all subsequent arguments are passed to
  // any callbacks on that event. So HB.trigger("foo", 1, 2) will pass the arguments (1,2)
  // to each callback set via HB.on, so HB.on("foo", function(a,b){alert(a+b)}) would alert
  // 3 in this case.
  trigger: function()
  {
    var eventName = arguments[0];
    if ( HB.eventCallbacks && HB.eventCallbacks[eventName] )
    {
      var l = HB.eventCallbacks[eventName].length;
      var origArgs = [];
      for(var i=1;i<arguments.length;i++)
      {
        origArgs.push(arguments[i]);
      }
      for(i=0;i<l;i++)
      {
        // Notice that we do setTimeout which causes the callback to happen
        // asynchronously
        (function(eventName, i){
          setTimeout(function(){
            (HB.eventCallbacks[eventName][i]).apply(HB, origArgs);
          }, i)
        })(eventName, i);
      }
    }
  },

  // Returns a SiteElement object from a hash of data
  createSiteElement: function(data)
  {
    var siteElement;

    // Sanitize the data
    data = HB.sanitize(data);
    // Make a copy of the siteElement
    var fn = window.HB[data.type + 'Element'];
    if(typeof fn === 'function') {
      siteElement = new window.HB[data.type + 'Element'](data);
    } else {
      siteElement = new HB.SiteElement(data);
    }

    siteElement.dataCopy = data;
    return siteElement;
  },

  // Adds the SiteElement to the page
  addToPage: function(siteElement)
  {
    if(siteElement.use_question) {
      siteElement = HB.questionifySiteElement(siteElement);
    }
    // Return if already added to the page
    if ( typeof(siteElement.pageIndex) != 'undefined' )
        return;
    // Set the page index so it can be referenced
    siteElement.pageIndex = HB.siteElementsOnPage.length;

    // Helper for template that returns the Javascript for a reference
    // to this object
    siteElement.me = "window.parent.HB.siteElementsOnPage["+siteElement.pageIndex+"]";

    HB.siteElementsOnPage.push(siteElement);

    // If there is a #nohb in the has we don't render anything
    if ( document.location.hash == "#nohb" )
      return;
    siteElement.attach();
  },

  removeAllSiteElements: function()
  {
    for(var i=0;i<HB.siteElementsOnPage.length;i++)
    {
      HB.siteElementsOnPage[i].remove();
    }
    HB.siteElementsOnPage = [];
  },

  // Called when the siteElement is viewed
  viewed: function(siteElement)
  {
    // Track number of views if not yet converted for this site element
    if(!HB.didConvert(siteElement))
      HB.s("v", siteElement.id, {a:HB.getVisitorAttributes()});

    // Record the number of views, first seen and last seen
    HB.setSiteElementData(siteElement.id, "nv", (HB.getSiteElementData(siteElement.id, "nv") || 0)+1);
    var now = Math.round((new Date()).getTime()/1000);
    if ( !HB.getSiteElementData(siteElement.id, "fv") )
      HB.setSiteElementData(siteElement.id, "fv", now);
    HB.setSiteElementData(siteElement.id, "lv", now);
    // Trigger siteElement shown event
    HB.trigger("siteElementshown", siteElement);
  },

  // Injects the specified element at the top of the body tag
  // or bottom if reverse is selected
  injectAtTop:function(element, reverse)
  {
    reverse = typeof reverse !== 'undefined' ? reverse : false;

    if ( !reverse && document.body.children.length > 0 )
      document.body.insertBefore(element,document.body.children[0]);
    else
      document.body.appendChild(element);
  },


  // Adds a rule to the list of rules.
  //  matchType: is either "any" or "all" - refers to the conditions
  //  conditions: serialized array of conditions for the rule to be true
  //  siteElements: serialized array of siteElements if the rule is true
  addRule: function(matchType, conditions, siteElements)
  {
    // First check to see if siteElements is an array, and make it one if it is not
    if (Object.prototype.toString.call(siteElements) !== "[object Array]")
      siteElements = [siteElements];

    // Create the rule
    var rule = {matchType: matchType, conditions: conditions, siteElements: siteElements};
    HB.rules.push(rule);
    // Set the rule on all of the siteElements
    for(var i=0;i<siteElements.length;i++)
    {
      siteElements[i].rule = rule;
    }
  },

  // If window.HB_element_id is set, use that to find the site element
  // Will return null if HB_element_id is not set or no site element exists with that id
  getFixedSiteElement: function () {
    if(window.HB_element_id != null) {
      for(i=0;i<HB.rules.length;i++)
      {
        var rule = HB.rules[i];
        for(j=0;j<rule.siteElements.length;j++)
        {
          var siteElement = rule.siteElements[j];
          if(siteElement.wordpress_bar_id == window.HB_element_id)
            return siteElement;
        }
      }
    }
    return null;
  },

  // applyRules scans through all the rules added via addRule and finds the
  // all rules that are true and pushes the site elements into a list of
  // possible results. Next it tries to find the "highest priority" site
  // elements (e.g. collecting email if not collected, etc). From there
  // we use multi-armed bandit to determine which site element to return
  applyRules: function()
  {
    var i,j,siteElement;
    var visibilityGroups = {};
    var visibilityGroup;
    var visibilityGroupNames = [];
    // First get all the site elements from all the rules that the
    // person matches

    for(i=0;i<HB.rules.length;i++)
    {
      var rule = HB.rules[i];

      if ( HB.ruleTrue(rule) )
      {
        // Get all site elements that are a part of this rule that the
        // visitor has not done
        for(j=0;j<rule.siteElements.length;j++)
        {
          siteElement = rule.siteElements[j];

          if(!HB.shouldShowElement(siteElement))
            continue;

          visibilityGroup = siteElement.type;
          // For showing multiple elements at the same time a modal and a takeover are the same thing
          if ( siteElement.type == "Modal" || siteElement.type == "Takeover" )
            visibilityGroup = "Modal/Takeover";
          if ( !visibilityGroups[visibilityGroup] )
          {
            visibilityGroups[visibilityGroup] = [];
            visibilityGroupNames.push(visibilityGroup);
          }
          visibilityGroups[visibilityGroup].push(siteElement);
        }
      }
    }
    // Now we have all elements that can be shown based on the rules
    // broken up into visibility groups
    // The next step is to pick one per visibility group
    var results = [];
    // We need to specify the order that elements appear in. Whichever is first
    // in the array is on top
    var visibilityOrder = ["Modal/Takeover", "Slider", "Bar"];
    for(i=0;i<visibilityOrder.length;i++)
    {
      if ( visibilityGroups[visibilityOrder[i]] )
      {
        siteElement = HB.getBestElement(visibilityGroups[visibilityOrder[i]]);
        if ( siteElement )
          results.push(siteElement);
      }
    }
    return results;
  },

  // Determine if an element should be displayed
  shouldShowElement: function(siteElement) {
    // Skip the site element if they have already seen/dismissed it
    // and it hasn't been changed since then and the user has not specified
    // that we show it regardless
    if ( (HB.convertedOrDismissed(siteElement) && !HB.updatedSinceLastVisit(siteElement)) || HB.nonMobileClickToCall(siteElement) ) {
      return false;
    } else {
      return true;
    }
  },

  nonMobileClickToCall: function(siteElement) {
    return siteElement.subtype == "call" && HB.getVisitorData("dv") !== "mobile";
  },

  convertedOrDismissed: function(siteElement) {
    var converted = HB.didConvert(siteElement) && !siteElement.show_after_convert;
    return converted || HB.didDismissThisHB(siteElement) || HB.didDismissHB();
  },

  updatedSinceLastVisit: function(siteElement) {
    var lastVisited = new Date(HB.getSiteElementData(siteElement.id, "lv")*1000);
    var lastUpdated = new Date(siteElement.updated_at);

    return lastUpdated > lastVisited;
  },

  // Returns the best element to show from a group of elements
  getBestElement: function(elements)
  {
    var i, siteElement;
    var possibleSiteElements = {};
    for(i=0;i<elements.length;i++)
    {
      siteElement = elements[i];
      if ( !possibleSiteElements[siteElement.subtype] )
        possibleSiteElements[siteElement.subtype] = [];
      possibleSiteElements[siteElement.subtype].push(siteElement);
    }

    // Now we narrow down based on the "value" of the site elements
    // (collecting emails is considered more valuable than clicking links
    // for example)
    if ( possibleSiteElements.email )
      possibleSiteElements = possibleSiteElements.email;
    else if ( possibleSiteElements.call )
      possibleSiteElements = possibleSiteElements.call;
    else if ( possibleSiteElements.social )
      possibleSiteElements = possibleSiteElements.social;
    else if ( possibleSiteElements.traffic )
      possibleSiteElements = possibleSiteElements.traffic;
    else if ( possibleSiteElements.announcement )
      possibleSiteElements = possibleSiteElements.announcement;
    else
      return; // Should not reach here - if we do there is nothing to show

    // If we have no elements then stop
    if ( !possibleSiteElements || possibleSiteElements.length == 0 )
      return;
    // If we only have one element just show it
    if ( possibleSiteElements.length == 1 )
      return possibleSiteElements[0];
    // First we should see if the visitor has seen any of these site elements
    // If so we should show them the same element again for a consistent
    // user experience.
    for(i=0;i<possibleSiteElements.length;i++)
    {
      if ( HB.getSiteElementData(possibleSiteElements[i].id, "nv") )
        return possibleSiteElements[i];
    }
    // We have more than one possibility so first we check for site elements
    // with less than 1000 views
    var siteElementsWithoutEnoughViews = [];
    for(i=0;i<possibleSiteElements.length;i++)
    {
      if ( possibleSiteElements[i].views < 1000 )
        siteElementsWithoutEnoughViews.push(possibleSiteElements[i]);
    }
    // If we have at least one element without enough views pick
    // randomly from them
    if ( siteElementsWithoutEnoughViews.length >= 1 )
    {
      return siteElementsWithoutEnoughViews[Math.floor((Math.random() * siteElementsWithoutEnoughViews.length))]
    }
    // So now we have more than one site element all with enough views
    // We need to determine if we are going to explore or exploit
    if ( Math.random() >= 0.9 )
    {
      // Explore mode
      // Just return a random site element
      return possibleSiteElements[Math.floor((Math.random() * possibleSiteElements.length))]
    }
    else
    {
      // Exploit mode
      // Return the site element with the highest conversion rate
      possibleSiteElements.sort(function(a, b){
        if (a.conversion_rate < b.conversion_rate)
          return 1;
        else if (a.conversion_rate > b.conversion_rate)
          return -1;
        return 0;
      });
      // Return the top value
      return possibleSiteElements[0];
    }
  },

  // Checkes if the rule is true by checking each of the conditions and
  // the matching logic of the rule (any vs all).
  ruleTrue: function(rule)
  {
    for(var i=0;i<rule.conditions.length;i++)
    {
      if ( HB.conditionTrue(rule.conditions[i]) )
      {
        // If we just need to match any condition and we have matched
        // one then return true
        if ( rule.matchType == "any" )
          return true;
      }
      else
      {
        // We didn't match a condition. Return false if we needed to
        // match all of them
        if ( rule.matchType != "any" )
          return false;
      }
    }
    // If we needed to match any condition (and we had at least one)
    // and didn't yet return false
    if ( rule.matchType == "any" && rule.conditions.length > 0)
      return false;
    return true;
  },

  // Determines if the condition (a rule is made of one or more conditions)
  // is true. It gets the current value and applies the operand
  conditionTrue: function(condition)
  {
    // Handle for URL Query
    if ( condition.segment === "pq" )
    {
      var conditionKey = condition.value.split("=")[0];
      var currentValue = HB.getSegmentValue(condition.segment)[conditionKey];
      var values = condition.value.split("=")[1] || "";
    }
    else {
      var currentValue = HB.getSegmentValue(condition.segment);
      var values = condition.value;
    }

    // Now we need to apply the operands
    // If it's an array of values this is true if the operand is true for any of the values

    // We don't want to mess with the array for the between operand
    if ( condition.operand == "between" )
      return HB.applyOperand(currentValue, condition.operand, values, condition.segment);

    // Put the value in an array if it is not an array
    if ( typeof(values) != "object" || typeof(values.length) != "number" )
      values = [values];

    // For negative/excluding operands we use "and" logic:
    if ( condition.operand.match(/not/) )
    {
      // Must be true for all so a single false means it is false for whole condition
      for(i=0;i<values.length;i++)
      {
        if (!HB.applyOperand(currentValue, condition.operand, values[i], condition.segment))
          return false;
      }
      return true;
    }
    else
    {
      // For including/positive operands we use "or" logic
      // Must be true for just one, so a single true is true for condition
      for(i=0;i<values.length;i++)
      {
        if (HB.applyOperand(currentValue, condition.operand, values[i], condition.segment))
          return true;
      }
      return false;
    }
  },

  // Sanitizes the value parameter based on the segment and input
  // Value is the value to sanitize
  // Input is the users value condition
  sanitizeConditionValue: function(segment, value, input)
  {
    if ( segment == "pu" || segment == "pp" || segment == "pup") {
      var relative = /^\//.test(input);
      value = HB.n(value, relative);
    }

    return value;
  },

  // Gets the current segment value that will be compared to the conditions
  // value
  getSegmentValue: function(segmentName)
  {
    // Convert long names to short names
    if ( segmentName == "url" )
      segmentName = "pu";
    else if ( segmentName == "device" )
      segmentName = "dv";
    else if ( segmentName == "country" )
      segmentName = "co";
    else if ( segmentName == "referrer" || segmentName == "referer" )
      segmentName = "rf";
    else if ( segmentName == "date" )
      segmentName = "dt";

    // All other segment names
    return HB.getVisitorData(segmentName);
  },

  // Applies the operand specified to the arguments passed in
  applyOperand: function(currentValue, operand, input, segment)
  {
    var a = HB.sanitizeConditionValue(segment, currentValue, input);
    var b = HB.sanitizeConditionValue(segment, input, input);

    switch(operand)
    {
      case "is":
      case "equals":
        if(typeof a === 'string' && typeof b === 'string') {
          var regex = new RegExp("^" + HB.sanitizeRegexString(b).replace("*", ".*") + "$");
          return !!a.match(regex);
        }
        return a == b;
      case "every":
        return a % b == 0;
      case "is_not":
      case "does_not_equal":
        return a != b;
      case "includes":
        if(typeof a === "undefined" && b === "")
           return false;
        if(typeof a === 'string' && typeof b === 'string') {
          var regex = new RegExp(HB.sanitizeRegexString(b).replace("*", ".*"));
          return !!a.match(regex);
        }

        return HB.stringify(a).indexOf(HB.stringify(b)) != -1;
      case "does_not_include":
        if(typeof a === "undefined" && b === "")
          return true;
        return HB.stringify(a).indexOf(HB.stringify(b)) == -1;
      case "before":
      case "less_than":
        return a < b;
      case "less_than_or_equal":
        return a <= b;
      case "after":
      case "greater_than":
        return a > b;
      case "greater_than_or_equal":
        return a >= b;
      case "between":
      case "is_between":
        return a >= b[0] && a <= b[1];
    }
  },

  // Returns a normalized string value
  // Used for applying operands
  stringify: function(o)
  {
    return (o+"").toLowerCase();
  },

  // This just sets the default segments/tracking data for the visitor
  // (such as when the suer visited, referrer, etc)
  setDefaultSegments: function()
  {
    var nowDate = new Date();
    var now = Math.round(nowDate.getTime()/1000);
    var hour = 60*60;
    var day = 24*hour;
    var newSession = 0;

    // Track first visit and most recent visit and time since
    // last visit
    if (!HB.getVisitorData("fv"))
        HB.setVisitorData("fv", now);
    // Get the previous visit
    var previousVisit = HB.getVisitorData("lv");

    // Set the time since the last visit as the number
    // of days
    if ( previousVisit )
      HB.setVisitorData("ls", Math.round((now-previousVisit)/day));
      if(((now - previousVisit) / hour) > 1) {
        newSession = 1;
      }

    HB.setVisitorData("lv", now);

    // Set the life of the visitor in number of days
    HB.setVisitorData("lf", Math.round((now-HB.getVisitorData("fv"))/day));

    // Track number of visitor visits
    HB.setVisitorData("nv", (HB.getVisitorData("nv") || 0)+1);

    // Track number of visitor sessions
    HB.setVisitorData("ns", (HB.getVisitorData("ns") || 0) + newSession);

    // Check for UTM params
    var params = HB.paramsFromString(document.location);

    HB.setVisitorData('ad_so', params['utm_source'], true);
    HB.setVisitorData('ad_ca', params['utm_campaign'], true);
    HB.setVisitorData('ad_me', params['utm_medium'], true);
    HB.setVisitorData('ad_co', params['utm_content'], true);
    HB.setVisitorData('ad_te', params['utm_term'], true);

    HB.setVisitorData('pq', params, true)

    // Set referrer if it is from a different domain (don't count internal referrers)
    if ( document.referrer )
    {
      var tld = HB.getTLD().toLowerCase();
      // Check to ensure that the tld is not present in the
      var referrer = (document.referrer+"").replace(/.*?\:\/\//,"").replace(/www\./i,"").toLowerCase().substr(0,150);
      var referrerDomain = referrer.replace(/(.*?)\/.*/, "$1");
      if ( referrerDomain.indexOf(tld) == -1 )
      {
        // This is an external referrer
        // Set the original referrer if not set
        if ( !HB.getVisitorData("or" ))
          HB.setVisitorData("or", referrer);
        // Set the full current referrer
        HB.setVisitorData("rf", referrer);
        // Set the referrer domain
        HB.setVisitorData("rd", referrerDomain);

        // Check for search terms
        var referrerParams = HB.paramsFromString(document.referer);
        // Check for search terms
        HB.setVisitorData("st", referrerParams['query'] || referrerParams['q'] || referrerParams['search'], true);
      }

      // Always set the previous page to the referrer
      HB.setVisitorData("pp", referrer);
    } else {
      // There is no referrer so set the "rf" and "rd" segments to blank
      HB.setVisitorData("rf", "");
      HB.setVisitorData("rd", "");
      HB.setVisitorData("pp", "");
    }
    // Set the page URL
    HB.setVisitorData("pu", HB.n(document.location+"", false));

    // Set the page path
    HB.setVisitorData("pup", HB.n(document.location.pathname, true));

    // Set the date
    HB.setVisitorData("dt", (HB.ymd(HB.nowInTimezone())));
    // Detect the device
    HB.setVisitorData("dv", HB.device());
  },

  paramsFromString: function(url)
  {
    var params = {};
    if ( !url )
      return params;
    url += ""; // cast to string
    var query = url.indexOf("?") == -1 ? url : url.split("?")[1];
    if ( !query )
      return params;
    var pairs = query.split("&");
    for(var i=0;i<pairs.length;i++)
    {
      var key, value;
      var components = pairs[i].split("=");
      components[1] || (components[1] = ''); // default the key to an empty string

      // handle ASCII encoding
      utf8bytes = unescape(encodeURIComponent(components[0]));
      key = decodeURIComponent(escape(utf8bytes)).toLowerCase();

      utf8bytes = unescape(encodeURIComponent(components[1]));
      value = decodeURIComponent(escape(utf8bytes));

      params[key] = value;
    }
    return params;
  },

  paramsToString: function(params)
  {
    var pairs = [];
    for(var k in params)
    {
      if ( typeof(params[k]) != "function" )
      {
        pairs.push(encodeURIComponent(k)+"="+encodeURIComponent(params[k]));
      }
    }
    return pairs.join("&");
  },

  // This code returns the root domain of the current site so "www.yahoo.co.jp" will return "yahoo.co.jp" and "blog.kissmetrics.com
  // will return kissmetrics.com. It does so by setting a cookie on each "part" until successful (first tries ".jp" then ".co.jp"
  // then "yahoo.co.jp"
  getTLD: function(){
    var i,h,
    wc='tld=ck',
    hostname = document.location.hostname.split('.');
    for(i=hostname.length-1; i>=0; i--) {
      h = hostname.slice(i).join('.');
      document.cookie = wc + ';domain=.' + h + ';';
      if(document.cookie.indexOf(wc)>-1){
        document.cookie = wc.split('=')[0] + '=;domain=.' + h + ';expires=Thu, 01 Jan 1970 00:00:01 GMT;';
        return h;
      }
    }
    return document.location.hostname;
  },

  // Takes the given element and "shakes" it a few times and returns
  // it to its original style and positioning. Used to shake the
  // email field when it is invalid.
  shake: function(element){
    (function(element){
      var velocity = 0;
      var acceleration = -0.1;
      var maxTravel = 1;
      // Store the original position
      var origPosition = element.style.position;
      var origX = parseInt(element.style.left, 0) || 0;
      var x = origX;
      var numShakes = 0;
      // Set the positioning to relevant
      element.style.position = "relative";
      var interval = setInterval(function(){
        velocity += acceleration;
        if ( x-origX >= maxTravel && acceleration > 0)
          acceleration *= -1;
        if ( x-origX <= -maxTravel && acceleration < 0)
        {
          numShakes += 1;
          acceleration *= -1;
        }
        x += velocity;
        if ( numShakes >= 2 && x >= origX )
        {
          clearInterval(interval);
          element.style.left = origX+"px";
          element.style.position = origPosition;
        }
        element.style.left = Math.round(x)+"px";
      }, 5);
    })(HB.$(element));
  },

  colorIsBright: function(hex) {
    var rgb = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if(rgb == null)
      return true;

    var brightness = HB.luminance(parseInt(rgb[1], 16), parseInt(rgb[2], 16), parseInt(rgb[3], 16));

    return brightness >= 0.5
  },

  luminance: function (r, g, b) {
    // http://www.w3.org/TR/2008/REC-WCAG20-20081211/#relativeluminancedef
    var rgb = [r, g, b];

    for(var i=0; i<3; i++) {
      var val = rgb[i] / 255;
      val = val < .03928 ? val / 12.92 : Math.pow((val + .055) / 1.055, 2.4);
      rgb[i] = val;
    }

    return .2126 * rgb[0] + .7152 * rgb[1] + 0.0722 * rgb[2];
  },

  animateIn: function(element, time){
    // HTML 5 supported so show the animation
    if (typeof element.classList == 'object') {
      element.classList.remove("hb-animateOut");
      element.classList.add("hb-animated");
      element.classList.add("hb-animateIn");
    }

    HB.showElement(element); // unhide if hidden
  },

  animateOut: function(element, callback){
    // HTML 5 supported so show the animation
    if (typeof element.classList == 'object') {
      element.classList.remove("hb-animateIn");
      element.classList.add("hb-animated");
      element.classList.add("hb-animateOut");
    } // else just hide
    else {
      HB.hideElement(element);
    }

    // if a callback is given, wait for animation then execute
    if(typeof(callback) == 'function') {
      window.setTimeout(callback, 250);
    }
  },

  // Delays & restarts wiggle animation before & after mousing over bar
  wiggleEventListeners: function(element){
    $(element)
      .on('mouseenter', '#hellobar', function(){
        $('#hellobar').find('.hellobar-cta').removeClass('wiggle');
      })
      .on('mouseleave', '#hellobar', function(){
        setTimeout( function(){
          $('#hellobar').find('.hellobar-cta').addClass('wiggle');
        }, 2500);
      });
  },

  // Parses the zone and returns the offset in seconds. If it can
  // not be parsed returns null.
  // Valid formats for zone are:
  // "HHMM", "+HHMM", "-HHMM", "HH:MM", "+HH:MM and "-HH:MM".
  parseTimezone: function(zone)
  {
    if ( !zone || typeof(zone) != "string" )
      return null;
    // Add + if missing +/-
    if ( zone[0] != '+' && zone[0] != '-' )
      zone = "+"+zone;
    if ( zone.indexOf(":") == -1 )
      zone = zone.slice(0, zone.length-2) + ":" + zone.slice(zone.length-2);
    if ( !zone.match(/^[\+-]\d{1,2}:\d\d$/) )
      return null;
    // Parse it
    var parts = zone.split(":");
    var signMultiplier = zone[0] == "+" ? 1 : -1;
    var hour = Math.abs(parseInt(parts[0], 10));
    var minute = parseInt(parts[1], 10);

    return ((hour*60*60)+(minute*60))*signMultiplier;
  },

  // Returns a Date object adjusted to the timezone specified (if none is
  // specified we try to use HB_TZ - if that is not present we use the user
  // timezone. The timezone of the actual Date object wills till be the
  // user's timezone since this can not be changed, but it will be offset
  // by the correct hours and minutes of the zone passed in.
  // If no valid format is found we use the current user's timezone
  // You can also pass in the value "visitor" which will use the visitor's
  // timezone
  nowInTimezone: function(zone)
  {
    // If no zone is specified try the HB_TZ variable
    if ( !zone && typeof(HB_TZ) == "string" )
      zone = HB_TZ;
    var zoneOffset = HB.parseTimezone(zone);
    if ( zoneOffset === null )
      return new Date();
    var now = new Date();
    return new Date(now.getTime()+(now.getTimezoneOffset()*60*1000)+(zoneOffset*1000))
  },

  ymd: function(date) {
    if (typeof date === "undefined") date = new Date();
    var m = date.getMonth() + 1;
    return date.getFullYear() + "-" + this.zeropad(m) + "-" + this.zeropad(date.getDate());
  },

  // Copied from zeropad.jquery.js
  zeropad: function(string, length) {
    // default to 2
    string = string.toString();
    if (typeof length === "undefined" && string.length == 1) length = 2;
    length = length || string.length;
    return string.length >= length ? string : this.zeropad("0" + string, length);
  },

  // Takes an input ID and returns an obfuscated ID
  // This is the required format for IDs for hi.hellobar.com
  obfID: function(number)
  {
    var SEP = "-";
    var ZERO_ENCODE = "_";
    var ENCODE = "S6pjZ9FbD8RmIvT3rfzVWAloJKMqg7CcGe1OHULNuEkiQByns5d4Y0PhXw2xta";
    var id = number+"";
    var outputs = [];
    var initialInputs = [id.slice(0,3), id.slice(3,6), id.slice(6,9)];
    var inputs = [];
    var i;
    for(i=0;i<initialInputs.length;i++)
    {
      if (initialInputs[i])
        inputs.push(initialInputs[i]);
    }
    for(i=0;i<inputs.length;i++)
    {
      var output = "";
      var chars = inputs[i].split("");
      for(var c=0;c<chars.length;c++)
      {
        if ( chars[c] != "0")
          break;
        output += ZERO_ENCODE;
      }
      var inputInt = parseInt(inputs[i], 10);
      if ( inputInt != 0 )
      {
        while(1)
        {
          var val;
          if ( inputInt > ENCODE.length )
            val = Math.floor((Math.random() * ENCODE.length) + 1);
          else
            val = Math.floor((Math.random() * inputInt) + 1);
          output += ENCODE[val-1];
          inputInt -= val;
          if ( inputInt <= 0 )
            break;
        }
      }
      outputs.push(output);
    }
    return outputs.join(SEP);
  },

  // Signs a given path and params with the provided key
  signature: function(key, path, params)
  {

    // NOTE: This is using the unencoded values for the params because
    // we don't want to get different signatures if one library encodes a
    // space as "+" and another as "%20" for example
    var sortedParamPairs = [];
    for(var k in params)
    {
      if (typeof(params[k]) != 'function' && k != "s")
      {
        sortedParamPairs.push(k+"="+params[k]);
      }
    }
    sortedParamPairs.sort();

    return HBCrypto.HmacSHA512(path+"?"+sortedParamPairs.join("|"), key).toString();

  },

  // Runs a function if the visitor has scrolled to a given height.
  scrollTargetCheck: function(scrollTarget, payload) {
    // scrollTarget of "bottom" and "middle" are computed during check, in case page size changes;
    // scrollTarget also accepts distance from top in pixels

    if (scrollTarget === "bottom") {
      // arbitrary 300 pixels subtracted from page height to assume visitor will not scroll through a footer
      scrollTarget = (document.body.scrollHeight - window.innerHeight - 300);
    }
    else if (scrollTarget === "middle") {
      // triggers just before middle of page - feels right due to polling rate
      scrollTarget = ((document.body.scrollHeight - (window.innerHeight * 2)) / 2);
    };

    // first condition checks if visitor has scrolled.
    // second condition guards against pages too small to scroll, displays immediately.
    // window.pageYOffset is same as window.scrollY, but with better compatibility.
    if (window.pageYOffset >= scrollTarget || document.body.scrollHeight <= scrollTarget + window.innerHeight) {
      payload();
    }
  },

  // Runs a function "payload" if the visitor meets intent-detection conditions
  intentCheck: function(intentSetting, payload) {
    var vistorIntendsTo = false;

    // if intent is set to exit and we have enough mouse position data...
    if (intentSetting === "exit") {

      // catch a keyboard move towards the address bar via onBlur event; resets onBlur state
      if ( HB.intentConditionCache.intentBodyBlurEvent ) {
        vistorIntendsTo = true;
        HB.intentConditionCache.intentBodyBlurEvent = false;
      }

      if ( HB.intentConditionCache.mousedOut ) {
        vistorIntendsTo = true;
      }

      //  catch page inactive state
      if ( document.hidden || document.unloaded ) { vistorIntendsTo = true };

      // if on mobile, display the bar after N ms regardless of mouse behavior
      var mobileDelaySetting = 30000;
      var date = new Date();
      if ( HB.device() === "mobile" && date.getTime() - HB.intentConditionCache.intentStartTime > mobileDelaySetting) {
        vistorIntendsTo = true
      };
    };

    if (vistorIntendsTo) {
      payload();
    };
  },

  initializeIntentListeners: function() {
    HB.intentConditionCache = {
      mouseInTime: null,
      mousedOut: false,
      intentBodyBlurEvent: false,
      intentStartTime: (new Date()).getTime()
    };

    // When a mouse enters the document, reset the mouseOut state and
    // set the time the document was entered
    document.body.addEventListener("mouseenter", function(e) {
      if(!HB.intentConditionCache.mouseInTime) {
        HB.intentConditionCache.mousedOut = false;
        HB.intentConditionCache.mouseInTime = new Date();
      }
    });

    // captures state of whether event has fired (ex: keyboard move to address bar)
    // response to this state defined by rules inside the intentCheck loop
    document.body.onblur = function() {
      HB.intentConditionCache.intentBodyBlurEvent = true;
    };

    // When the mouse leaves the document, check the current time vs when the mouse entered
    // the document.  If greater than the specified timespan, set the mouseOut state
    document.body.addEventListener("mouseleave", function(e) {
      if(HB.intentConditionCache.mouseInTime) {
        var currentTime = new Date();
        if(currentTime.getTime() - HB.intentConditionCache.mouseInTime.getTime() > 2000) {
          HB.intentConditionCache.mouseInTime = null;
          HB.intentConditionCache.mousedOut = true;
        }
      }
    });
  },

  branding_template: function() {
    var stored = HB.gc("b_template");
    return stored != null ? stored : HB.CAP.b_variation;
  },

  hideElement: function(element) {
    if(element == null) { return } // do nothing
    if(element.length == undefined){
      element.style.display = 'none';
    } else {
      for (var i = 0; i < element.length; ++i) {
        element[i].style.display = 'none';
      }
    }
  },

  showElement: function(element, display) {
    if (element == null) { return } // do nothing
    if(typeof display === 'undefined') {
      display = 'inline';
    }
    if(element.length == undefined){
      element.style.display = display;
    } else {
      for (var i = 0; i < element.length; ++i) {
        element[i].style.display = display;
      }
    }
  },

  // Replaces the site element with the question variation.
  // Sets the displayResponse callback to show the original element
  questionifySiteElement: function(siteElement) {
    if(!siteElement.use_question || !siteElement.dataCopy)
      return siteElement;

    // Create a copy of the siteElement
    var originalSiteElement = siteElement;
    siteElement = siteElement.dataCopy;

    // Set the template and headline
    // Remove the image from the question
    siteElement.template_name = siteElement.template_name.split("_")[0] + "_question";
    siteElement.headline = siteElement.question;
    siteElement.caption = null;
    siteElement.use_question = false;
    siteElement.image_url = null;

    // Create the new question site element
    siteElement = HB.createSiteElement(siteElement);

    // Set the callback.  When this is called, it sets the values on the original element
    // and displays it.
    siteElement.displayResponse = function(choice) {
      // If showResponse has not been set (ie, not forcing an answer to display)
      // trigger the answerSelected event
      if(!HB.showResponse) {
        HB.trigger("answerSelected", choice);
      }

      if(choice === 1) {
        originalSiteElement.headline  = siteElement.answer1response;
        originalSiteElement.caption   = siteElement.answer1caption;
        originalSiteElement.link_text = siteElement.answer1link_text;
      } else {
        originalSiteElement.headline  = siteElement.answer2response;
        originalSiteElement.caption   = siteElement.answer2caption;
        originalSiteElement.link_text = siteElement.answer2link_text;
      }

      // Dont use the question, otherwise we end up in a loop.
      // Also, don't animate in since the element will already be on the screen
      // Also, don't record the view since it's already been recorded
      originalSiteElement.use_question    = false;
      originalSiteElement.animated        = false;
      originalSiteElement.dontRecordView  = true;
      originalSiteElement.view_condition  = 'immediately';

      // Remove the siteElement and show the original in non preview environments
      if(!HB.CAP.preview) {
        siteElement.remove();
        HB.addToPage(originalSiteElement);
      }
    };

    // If showResponse is set the preview environments, skip right to showing the response
    if(HB.CAP.preview && HB.showResponse) {
      siteElement.displayResponse(HB.showResponse);
      siteElement = originalSiteElement;
    }

    return siteElement;
  },

  sample: function(items) {
    return items[ Math.floor(Math.random() * items.length) ];
  },

  // Sets the disableTracking cookie to true or false based on hb_ignore=
  setTracking: function(queryString) {
    if(queryString.match(/hb_ignore/i)) {
      var bool = !!queryString.match(/hb_ignore=true/i);
      HB.sc("disableTracking", bool, 5*365);
    }
  },

  setCustomConditionValue: function(segmentKey, value) {
    HB.setVisitorData(segmentKey, value);
    if(HB.siteElementsOnPage.length === 0) {
      HB.showSiteElements();
    }
  },

  getUserAgent: function() {
    return navigator.userAgent;
  },

  device: function() {
    var ua = HB.getUserAgent();
    if (ua.match(/ipad/i))
      return "tablet";
    else if (ua.match(/(mobi|phone|ipod|blackberry|docomo)/i))
      return "mobile";
    else if (ua.match(/(ipad|kindle|android)/i))
      return "tablet";
    else
      return "computer";
  },

  setGeolocationData: function(locationData) {
    locationCookie = {
      'gl_cty' : locationData.city,
      'gl_ctr' : locationData.countryCode,
      'gl_rgn' : locationData.region
    }

    // Don't let any cookies get set without a site ID
    if ( typeof(HB_SITE_ID) != "undefined")
    {
      //refresh geolocation every month on not mobile
      var expirationDays = 30;
      //refresh geolocation every day on mobile
      if ( HB.getVisitorData("dv") === "mobile" )
        expirationDays = 1;
      HB.sc("hbglc_"+HB_SITE_ID, HB.serializeCookieValues(locationCookie), expirationDays);
      HB.loadCookies();
    }
  },

  getGeolocationData: function(key) {
    var cachedLocation = HB.gc(key);
    if (cachedLocation) return cachedLocation;

    var xhr = new XMLHttpRequest();
    if ( HB.geoRequestInProgress == false ) {
      xhr.open('GET', HB_GL_URL);
      xhr.send(null);
      HB.geoRequestInProgress = true;
    }

    xhr.onreadystatechange = function () {
      var DONE = 4; // readyState 4 means the request is done.
      var OK = 200; // status 200 is a successful return.
      if (xhr.readyState === DONE) {
        if (xhr.status === OK) {
          response = JSON.parse(xhr.responseText);
          HB.setGeolocationData(response);
          HB.geoRequestInProgress = false;
          HB.showSiteElements();
        }
      }
    };
  },

  isIpAddress: function(ipaddress)
  {
    if (/^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/.test(ipaddress))
      return true;
    else
      return false;
  },

  // Escapes all regex characters EXCEPT for the asterisk
  sanitizeRegexString: function(str) {
    return str.replace(/[-[\]{}()+?.,\\^$|#\s]/g, "\\$&");
  }
};
