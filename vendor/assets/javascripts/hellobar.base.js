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
  HB.isMobile = false;
  HB.widthCache = 0;

  // Need to load the serialized cookies
  HB.loadCookies();

  // Once initialized replace the existing data with it
  if ( typeof(_hbq) != "undefined" && _hbq && _hbq.length ) {
    for ( var i=0; i<_hbq.length; i++ )
      this.push(_hbq[i]);
  }

  // Set all the default tracking trackings
  HB.setDefaultSegments();

  // Apply the rules
  var siteElement = HB.applyRules();
  if ( siteElement )
    HB.render(siteElement);

  // As the vistor readjust the window size we need to adjust the size of the containing
  // iframe. We do this by checking the the size of the inner div. If the the width
  // of the window is less than or equal to 640 pixels we set the flag isMobileWidth to true.
  // Note: we are not actually detecting a mobile device - just the width of the window.
  // If isMobileWidth is true we add an additional "mobile" CSS class which is used to
  // adjust the style of the siteElement.
  // To accomplish all of this we set up an interval to monitor the size of everything:
  HB.isMobileWidth = false;
  var mobileDeviceInterval = setInterval(function(){
    // Get the frame
    var frame = window.frames["hellobar_container"];
    if ( !frame )
      return;

    // Get the relevant elements that might need checking/adjusting
    var containerDocument = frame.document;
    HB.e = {
      container: HB.$("#hellobar_container"),
      pusher: HB.$("#hellobar_pusher")
    };

    if ( containerDocument ) {
      if ( containerDocument.getElementById("hellobar_bar") !== null ) {
        HB.e.siteElement = containerDocument.getElementById("hellobar_bar");
        HB.e.siteElementType = "bar";
      } else if ( containerDocument.getElementById("hellobar_modal") !== null ) {
        HB.e.siteElement = containerDocument.getElementById("hellobar_modal");
        HB.e.siteElementType = "modal";
      } else if ( containerDocument.getElementById("hellobar_slider") !== null ) {
        HB.e.siteElement = containerDocument.getElementById("hellobar_slider");
        HB.e.siteElementType = "slider";
      } else if ( containerDocument.getElementById("hellobar_takeover") !== null ) {
        HB.e.siteElement = containerDocument.getElementById("hellobar_takeover");
        HB.e.siteElementType = "takeover";
      } else  {
        HB.e.siteElement = false;
        HB.e.siteElementType = false;
      }
    }

    // Monitor siteElement height to update HTML/CSS
    if ( HB.e.siteElement ) {
      if ( HB.e.siteElement.clientHeight ) {

        // Update the CSS class based on the width
        var wasMobile = HB.isMobileWidth;

        if ( HB.e.siteElementType == "modal" && containerDocument )
          HB.isMobileWidth = (containerDocument.getElementById("hellobar_modal_background").clientWidth <= 640 );
        else if ( HB.e.siteElementType == "slider" )
          HB.isMobileWidth = (HB.e.siteElement.clientWidth <= 270 );
        else
          HB.isMobileWidth = (HB.e.siteElement.clientWidth <= 640 );

        if ( wasMobile != HB.isMobileWidth ) {
          HB.widthCache = 0;

          if ( HB.isMobileWidth ) {
            HB.isMobile = true;
            HB.addClass(HB.e.siteElement, "mobile");
          } else {
            HB.isMobile = false;
            HB.removeClass(HB.e.siteElement, "mobile");
          }
        }

        // Adjust the container size
        if ( HB.e.container && (HB.widthCache != HB.e.container.clientWidth || HB.e.siteElement.clientHeight != HB.heightCache)) {
          HB.setContainerSize(HB.e.container, HB.e.siteElement, HB.e.siteElementType, HB.isMobile);
          HB.widthCache = HB.e.container.clientWidth;
          HB.heightCache = HB.e.siteElement.clientHeight;
        }

        // Bar specific adjustments
        if ( HB.e.siteElementType == "bar" ) {

          // Adjust the pusher
          if ( HB.e.pusher ) {
            var borderPush = HB.t((HB.currentSiteElement.show_border) ? 3 : 0)
            HB.e.pusher.style.height = (HB.e.siteElement.clientHeight + borderPush) + "px";
          }

          // Add multiline class
          var barBounds = (HB.w.className.indexOf('regular') > -1 ? 32 : 52 );

          if ( HB.e.siteElement.clientHeight > barBounds ) {
            HB.addClass(HB.e.siteElement, "multiline");
          } else {
            HB.removeClass(HB.e.siteElement, "multiline");
          }
        }
      }
    }
  }, 50); // Check every 50ms
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
// **Special case: If a user includes multiple siteElements, to avoid overwriting the first siteElement and causing errors,
// we manually set _HB to HB later before pushing rules.
var _HB = {
  CAP: {}, // Capabilies

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
    // Add trailing slash when we think it's needed
    if ( url.match(/^https?:\/\/[^\/]*$/i) || url.match(/^[^\/]*\.(com|edu|gov|us|net|io)$/i))
      url += "/";

    // Get rid of things that make no difference in the URL (such as protocol and anchor)
    url = (url+"").toLowerCase().replace(/https?:\/\//,"").replace(/^www\./,"").replace(/\#.*/,"");
    // Strip the host if pathOnly
    if ( pathOnly )
    {
      // Unless it starts with a slash
      if ( !url.match(/^\//) )
          url = url.replace(/.*?\//, "/");
    }
    // Get the params
    var urlParts = url.split("?");
    // If no params just return the URL
    if ( !urlParts[1] )
      return HB.stripTrailingSlash(urlParts[0]);
    // Sort the params
    return HB.stripTrailingSlash(urlParts[0])+"?"+urlParts[1].split("&").sort().join("&");
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
  trackClick: function(element)
  {
    var url = element.href;
    HB.converted(function(){if(element.target != "_blank") document.location = url;});
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
  converted: function(callback)
  {
    var conversionKey = HB.getConversionKey(HB.currentSiteElement);
    var now = Math.round(new Date().getTime()/1000)

    // Set the number of conversions for the visitor for this type of conversion
    HB.setVisitorData(conversionKey, (HB.getVisitorData(conversionKey) || 0 )+1);
    // Record first time converted, unless already set for the visitor for this type of conversion
    HB.setVisitorData(conversionKey+"_f", now);
    // Record last time converted for the visitor for this type of conversion
    HB.setVisitorData(conversionKey+"_l", now);

    // Set the number of conversions for the specific site element
    HB.setSiteElementData(HB.si, "nc", (HB.getSiteElementData(HB.si, "nc") || 0)+1);
    // Set the first time converted for the site element if not set
    if ( !HB.getSiteElementData(HB.si, "fc") )
      HB.setSiteElementData(HB.si, "fc", now);
    // Set the last time converted for the site element to now
    HB.setSiteElementData(HB.si, "lc", now);
    // Trigger the event
    HB.trigger("conversion", HB.currentSiteElement);
    // Send the data to the backend
    HB.s("g", HB.si, {a:HB.getVisitorAttributes()}, callback);
  },

  // Returns true if the visitor did this conversion or not
  didConvert: function(siteElement)
  {
    return HB.getVisitorData(HB.getConversionKey(siteElement));
  },

  // This takes the the email field, name field, and target siteElement DOM element.
  // It then checks the validity of the fields and if valid it records the
  // email and then sets the message in the siteElement to "Thank you". If invalid it
  // shakes the email field
  submitEmail: function(emailField, nameField, targetSiteElement, thankYouText, removeElement)
  {
    HB.validateEmail(
      emailField.value,
      nameField.value,
      function(){
        if(targetSiteElement != null)
          targetSiteElement.innerHTML='<span>' + thankYouText + '</span>';
        if(removeElement != null)
          removeElement.style.display = "none";
        HB.recordEmail(emailField.value, nameField.value, function(){
          // Successfully saved
        });
      },
      function(){
        // Fail
        HB.shake(emailField);
      }
    );
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
  recordEmail: function(email, name, callback)
  {
    if ( email )
    {
      var emailAndName = email;
      if ( name )
        emailAndName += ","+name;

      // Record the email address to the cnact list and then track that the rule was performed
      HB.s("c", HB.cli, {e:emailAndName}, function(){HB.converted(callback)});
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
      HB.cookies = {siteElements:{}, visitor:{}};
    else
    {
      HB.cookies = {
        visitor: HB.parseCookieValues(HB.gc("hbv_"+HB_SITE_ID)),
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
    return HB.cookies.visitor[key];
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

  // Gets a cookie
  gc: function(name)
  {
    var i,x,y,c=document.cookie.split(";");
    for (i=0;i<c.length;i++)
    {
      x=c[i].substr(0,c[i].indexOf("="));
      y=c[i].substr(c[i].indexOf("=")+1);
      x=x.replace(/^\s+|\s+$/g,"");
      if (x==name)
      {
        return unescape(y);
      }
    }
  },

  // Sets a cookie
  sc: function(name,value,exdays)
  {
    if ( typeof(HB_NC) != "undefined" )
      return;
    var exdate=new Date();
    exdate.setDate(exdate.getDate() + exdays);
    value=escape(value) + ((exdays==null) ? "" : "; expires="+exdate.toUTCString());
    document.cookie=name + "=" + value;
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

  // Takes each string value in the siteElement and escapes HTML < > chars
  // with the matching symbol
  sanitize: function(siteElement){
    for (var k in siteElement){
      if (siteElement.hasOwnProperty(k) && siteElement[k] && siteElement[k].replace)
        siteElement[k] = siteElement[k].replace(/</g,'&lt;').replace(/>/g,'&gt;');
    }
    return siteElement;
  },

  isIEXOrLess: function(x) {
    var myNav = navigator.userAgent.toLowerCase();
    var version = (myNav.indexOf('msie') != -1) ? parseInt(myNav.split('msie')[1]) : false;

    if(isNaN(version) || version == null || version == false)
      return false;

    if (version <= x)
      return true;
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
    return (value === undefined ? "" : value);
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

  // Renders the siteElement
  render: function(siteElementToRender)
  {
    var siteElement = {};

    // Make a copy of the siteElement
    var fn = window[siteElementToRender.type + 'Element'];
    if(typeof fn === 'function') {
      siteElement = new window[siteElementToRender.type + 'Element'](siteElementToRender)
    } else {
      siteElement = new SiteElement(siteElementToRender)
    }

    // Call prerender
    siteElement.prerender();

    HB.currentSiteElement = siteElement;
    // Convenience accessors for commonl ussed attributes
    HB.si = siteElement.id;
    HB.cli = siteElement.contact_list_id;
    // If there is a #nohb in the has we don't render anything
    if ( document.location.hash == "#nohb" )
      return;
    // Replace all the templated variables
    var html = HB.renderTemplate(this.getTemplate(siteElement)+"", siteElement);
    // Once the dom is ready we inject the html returned from renderTemplate
    HB.domReady(function(){
      // Set an arbitrary timeout to prevent some rendering
      // conflicts with certain sites
      setTimeout(function(){
        HB.injectSiteElementHTML(html, siteElement);
        HB.setPullDown(siteElement)
        // Track the view
        HB.viewed();
        // Monitor zoom scale events
        HB.hideOnZoom();
        // Bounce in animation
        if(HB.w.className.indexOf("animated") > -1)
          setTimeout(function(){ HB.animateIn(HB.w); }, 500);
        // Set wiggle listeners
        if(siteElement.wiggle_button.length > 0)
          HB.wiggleEventListeners(HB.w);
      }, 1);
    });
  },

  // Called when the siteElement is viewed
  viewed: function()
  {
    // Track number of views
    HB.s("v", HB.si, {a:HB.getVisitorAttributes()});
    // Record the number of views, first seen and last seen
    HB.setSiteElementData(HB.si, "nv", (HB.getSiteElementData(HB.si, "nv") || 0)+1);
    var now = Math.round((new Date()).getTime()/1000);
    if ( !HB.getSiteElementData(HB.si, "fv") )
      HB.setSiteElementData(HB.si, "fv", now)
    HB.setSiteElementData(HB.si, "lv", now)
    // Trigger siteElement shown event
    HB.trigger("siteElementshown", HB.currentSiteElement);
  },

  hideOnZoom: function() {
    // Doesn't work IE 9 and earlier
    if (!window.addEventListener || !window.outerWidth || !window.innerWidth) return;

    var original = HB.w.style.position;
    var action = function(e) {
      var ratio = (window.outerWidth - 8) / window.innerWidth;
      if (e.scale) {
        // iPhone
        HB.w.style.position = (e.scale <= 1.03) ? original : 'absolute';
      } else if (typeof window.orientation !== 'undefined') { // Not mobile
        // Android
        if (window.outerWidth <= 480 && ratio <= 1.3) {
          return HB.w.style.position = original;
        }
        HB.w.style.position = (ratio <= 0.6) ? original : 'absolute';
      } else {
        // Desktop
        HB.w.style.position = (ratio <= 1.3) ? original : 'absolute';
      }
    };

    // iPhone
    window.addEventListener('gesturechange', action);

    // Android
    window.addEventListener('scroll', action);
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

  // Injects the specified HTML for the given siteElement into the page
  injectSiteElementHTML: function(html, siteElement)
  {
    // Remove the containing iframe element if it exists
    if ( HB.w &&  HB.w.parentNode)
      HB.w.parentNode.removeChild(HB.w);

    // Remove pull-arrow if it exists
    HB.pd = document.getElementById("pull-down")
    if ( HB.pd )
      HB.pd.parentNode.removeChild(HB.pd);

    // Create the iframe container
    HB.w = document.createElement("iframe");
    HB.w.src = "about:blank";
    HB.w.id = "hellobar_container";
    HB.w.className = siteElement.type;
    HB.w.name = "hellobar_container";

    siteElement.setupIFrame(HB.w)

    // Check if we have any external CSS to add
    if ( HB.extCSS )
    {
      // If we have already added it, remove it and re-add it
      if ( HB.extCSSStyle )
        HB.extCSSStyle.parentNode.removeChild(HB.extCSSStyle);
      // Create the CSS style tag
      HB.extCSSStyle = document.createElement('STYLE');
      HB.extCSSStyle.type="text/css";
      if(HB.extCSSStyle.styleSheet)
      {
        HB.extCSSStyle.styleSheet.cssText=HB.extCSS;
      }
      else
      {
        HB.extCSSStyle.appendChild(document.createTextNode(HB.extCSS));
      }
      var head=document.getElementsByTagName('HEAD')[0];
      head.appendChild(HB.extCSSStyle);
    }

    // Inject the container into the DOM
    HB.injectAtTop(HB.w);
    // Render the siteElement in the container.
    var d = HB.w.contentWindow.document;
    d.open();
    d.write("<html><head>" + (HB.css || "") + "</head><body>" + html + "</body></html>");
    d.close();
    d.body.className = siteElement.type;
    if(HB.isIEXOrLess(9))
      HB.addClass(d.body, "hb-old-ie");
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

  // applyRules scans through all the rules added via addRule and finds the
  // all rules that are true and pushes the site elements into a list of
  // possible results. Next it tries to find the "highest priority" site
  // elements (e.g. collecting email if not collected, etc). From there
  // we use multi-armed bandit to determine which site element to return
  applyRules: function()
  {
    var i,j,siteElement;
    var possibleSiteElements = [];
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
          if ( siteElement.subtype == "traffic" || !HB.didConvert(siteElement) )
          {
            if ( !possibleSiteElements[siteElement.subtype] )
              possibleSiteElements[siteElement.subtype] = [];
            possibleSiteElements[siteElement.subtype].push(siteElement);
          }
        }
      }

    }
    // Now we narrow down based on the "value" of the site elements
    // (collecting emails is considered more valuable than clicking links
    // for example)
    if ( possibleSiteElements.email )
      possibleSiteElements = possibleSiteElements.email;
    else if ( possibleSiteElements.social )
      possibleSiteElements = possibleSiteElements.social;
    else if ( possibleSiteElements.traffic )
      possibleSiteElements = possibleSiteElements.traffic;
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
    // Need to get the current value
    var currentValue = HB.getSegmentValue(condition.segment);
    // Now we need to apply the operands
    // If it's an array of values this is true if the operand is true for any of the values
    var values = condition.value;

    // We don't want to mess with the array for the between operand
    if ( condition.operand == "between" )
      return HB.applyOperand(currentValue, condition.operand, values);

    // Put the value in an array if it is not an array
    if ( typeof(values) != "object" || typeof(values.length) != "number" )
      values = [values];

    // Sanitize all values
    currentValue = HB.sanitizeConditionValue(condition.segment, currentValue);
    var i;
    for(i=0;i<values.length;i++)
    {
      values[i] = HB.sanitizeConditionValue(condition.segment, values[i]);
    }
    // For negative/excluding operands we use "and" logic:
    if ( condition.operand.match(/not/) )
    {
      // Must be true for all so a single false means it is false for whole condition
      for(i=0;i<values.length;i++)
      {
        if (!HB.applyOperand(currentValue, condition.operand, values[i]))
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
        if (HB.applyOperand(currentValue, condition.operand, values[i]))
          return true;
      }
      return false;
    }
  },

  sanitizeConditionValue: function(segment, value)
  {
    if ( segment == "pu" )
      value = HB.n(value, true);
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
  applyOperand: function(a, operand, b)
  {
    switch(operand)
    {
      case "is":
      case "equals":
        return a == b;
      case "is_not":
      case "does_not_equal":
        return a != b;
      case "includes":
        return HB.stringify(a).indexOf(HB.stringify(b)) != -1;
      case "does_not_include":
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
    var day = 24*60*60;

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
    HB.setVisitorData("lv", now);

    // Set the life of the visitor in number of days
    HB.setVisitorData("lf", Math.round((now-HB.getVisitorData("fv"))/day));

    // Track number of visitor visits
    HB.setVisitorData("nv", (HB.getVisitorData("nv") || 0)+1);

    // Check for UTM params
    var params = HB.paramsFromString(document.location);

    HB.setVisitorData('ad_so', params['utm_source'], true);
    HB.setVisitorData('ad_ca', params['utm_campaign'], true);
    HB.setVisitorData('ad_me', params['utm_medium'], true);
    HB.setVisitorData('ad_co', params['utm_content'], true);
    HB.setVisitorData('ad_te', params['utm_term'], true);
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
    }
    // Set the page URL
    HB.setVisitorData("pu", HB.n(document.location+"", true));
    // Set the date
    HB.setVisitorData("dt", (HB.ymd(HB.nowInTimezone())));
    // Detect the device
    var ua = navigator.userAgent;
    if (ua.match(/ipad/i))
      HB.setVisitorData("dv", "tablet");
    else if (ua.match(/(mobi|phone|ipod|blackberry|docomo)/i))
      HB.setVisitorData("dv", "mobile");
    else if (ua.match(/(ipad|kindle|android)/i))
      HB.setVisitorData("dv", "tablet");
    else
      HB.setVisitorData("dv", "computer");
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
      key = decodeURIComponent(components[0]).toLowerCase();
      value = decodeURIComponent(components[1]);
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
      element.classList.remove("animateOut");
      element.classList.add("animated");
      element.classList.add("animateIn");
    } // else just unhide
    else {
      element.style.display = "";
    }
  },

  animateOut: function(element, callback){
    // HTML 5 supported so show the animation
    if (typeof element.classList == 'object') {
      element.classList.remove("animateIn");
      element.classList.add("animated");
      element.classList.add("animateOut");
    } // else just hide
    else {
      element.style.display = "none";
    }

    // Makes Iframe small after hiding in order to allow click events.
    hideIframe = window.setTimeout(function(){
      var classes = element.getAttribute('class');
      if (classes != null && classes.indexOf('Bar') > -1 && !isBar && element.id != "pull-down"){
        element.setAttribute('style','height:0px;max-height:0px');
      }
      if(typeof(callback) == 'function') {
        callback();
      }
    }, 250);
  },

  closeIframe: function() {
    if(HB.w != null && HB.w.parentNode != null) {
      HB.w.parentNode.removeChild(HB.w)
    }

    HB.trigger("elementDismissed");
  },

  // Delays & restarts wiggle animation before & after mousing over bar
  wiggleEventListeners: function(element){
    $(element)
      .on('mouseenter', '#hellobar', function(){
        $('#hellobar').find('.hellobar_cta').removeClass('wiggle');
      })
      .on('mouseleave', '#hellobar', function(){
        setTimeout( function(){
          $('#hellobar').find('.hellobar_cta').addClass('wiggle');
        }, 2500);
      });
  },

  // Create the pulldown arrow element for when a bar is hidden
  // The pulldown arrow is only created when a site element is closable
  setPullDown: function(siteElement) {
    // Create the pull down elements
    if(siteElement.closable) {
      var pullDown = document.createElement("div");
      pullDown.className = siteElement.size + " hellobar " + siteElement.placement;
      pullDown.id = "pull-down";

      pullDown.style.backgroundColor = "#" + siteElement.background_color;
      var pdLink = document.createElement("div");
      pdLink.className = "hellobar_arrow";
      pdLink.onclick = function() {
        HB.animateIn(HB.w);
        HB.animateOut(document.getElementById("pull-down"));

        // if the pusher exists, unhide it since it should be hidden at this point
        if (HB.e.pusher != null)
          HB.e.pusher.style.display = '';
      };

      pullDown.appendChild(pdLink);
      HB.injectAtTop(pullDown);
    }
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

  setContainerSize: function(container, element, type, isMobile)
  {
    if (HB.e.container == null)
      return;
    if ( type == 'bar' ) {
      HB.e.container.style.maxHeight = (element.clientHeight + 8) + "px";
    } else if ( type == 'slider' ) {
      HB.e.container.style.height = (element.clientHeight + 24) + "px";
      HB.e.container.style.width = (element.clientWidth + 24) + "px";
    }
  },

  // Hides entire site element iframe 
  hideSiteElement: function()
  {
    HB.w.style.display = 'none';
  },

  // Unhides entire site element iframe 
  showSiteElement: function()
  {
    HB.w.style.display = 'block'
  },

  // Reads the site element's display_when setting and calls hide/show per selected behavior
  // if viewCondition is missing or badly formed, siteElement displays immidiately by default

  checkForDisplaySetting: function()
  {
    var viewCondition = HB.currentSiteElement.view_condition;

    if (document.getElementById('hellobar-preview-container') !== null) { viewCondition = 'preview'; console.log("I'm a preview")};
   
    if (viewCondition === 'immidiately') 
    {
      return; 
    } 
    else if (viewCondition === 'preview') 
    {
      // append message to preview function
      return;
    }
    else if (viewCondition === 'wait-5') 
    {
      HB.hideSiteElement();
      setTimeout(HB.showSiteElement, 5000);
    } 
    else if (viewCondition === 'wait-10') 
    {
      HB.hideSiteElement();
      setTimeout(HB.showSiteElement, 10000);
    } 
    else if (viewCondition === 'wait-60') 
    {
      HB.hideSiteElement();
      setTimeout(HB.showSiteElement, 60000);
    } 
    else if (viewCondition === 'scroll-some') 
    {
      // scroll-some is defined here as "visitor scrolls 300 pixels"
      HB.hideSiteElement();
      HB.scrollInterval = setInterval(HB.scrollTargetCheck, 500, 300, HB.showSiteElement);  
    }
    else if (viewCondition === 'scroll-middle') 
    {
      HB.hideSiteElement();
      HB.scrollInterval = setInterval(HB.scrollTargetCheck, 500, "middle", HB.showSiteElement);  
    }
    else if (viewCondition === 'scroll-to-bottom') 
    {
      HB.hideSiteElement();
      HB.scrollInterval = setInterval(HB.scrollTargetCheck, 500, "bottom", HB.showSiteElement);  
    }
    else if (viewCondition === 'exit-intent') 
    {
      HB.hideSiteElement();
      HB.intentInterval = setInterval(HB.intentCheck, 100, "exit", HB.showSiteElement);  
    };
  },

  // Runs a function if the visitor has scrolled to a given height.   
  scrollTargetCheck: function(scrollTarget, payload) {
    // scrollTarget of "bottom" and "middle" are computed during check, in case page size changes;
    // scrollTarget also accepts distance from top in pixels

    if (scrollTarget === "bottom") {
      // arbitrary 300 pixels subtracted from page height to assume visitor will not scroll through a footer
      scrollTarget = (document.body.scrollHeight - document.body.clientHeight - 300);
    }
    else if (scrollTarget === "middle") {
      // triggers just before middle of page - feels right due to polling rate
      scrollTarget = ((document.body.scrollHeight - (document.body.clientHeight * 2)) / 2);
    };

    // window.pageYOffset is same as window.scrollY, but with better compatibility
    if (window.pageYOffset >= scrollTarget) {
      payload();
      clearInterval(HB.scrollInterval);
    }
  },

  // Runs a function if the visitor meets intent-detection conditions 
  intentCheck: function(intentSetting, payload) {
    var vistorIntendsTo = false;

    // aliases for readability
    var yFromBottom = (HB.mouseY - document.body.clientHeight) * -1;
    var xFromLeft = HB.mouseX;

     // Caches most recent polling data for reference by rules
    HB.intentConditionCache.push({ x: HB.mouseX, y: HB.mouseY, yFromBottom: yFromBottom });
    if (HB.intentConditionCache.length > 5) { HB.intentConditionCache.shift(); };
    var c = HB.intentConditionCache;

    if (intentSetting === "exit") {

      // catches fast move off screentop (same location across polls implies cursor out of viewport)
      if ((HB.mouseY < 75) 
        && (c[c.length - 1].x === c[c.length - 2].x) 
        && (c[c.length - 1].y === c[c.length - 2].y) 
        && (c[c.length - 1].y === c[c.length - 3].y) 
        && (c[c.length - 1].x === c[c.length - 3].x)) { vistorIntendsTo = true };

      // catches slow move off screentop (requires previous poll to be near edge)
      if (HB.mouseY < 2 && c[c.length - 2].y < 10) { vistorIntendsTo = true };

      // catches any move towards the back button 
      if (HB.mouseY + HB.mouseX < 200) { vistorIntendsTo = true };

      // Windows-ish only rules
      if (navigator.appVersion.indexOf("Win")!=-1) { 

        // catch any move towards Start Menu (bottom left) 
        if (yFromBottom + xFromLeft < 200) { vistorIntendsTo = true };
      };

      // OSX-ish only rules
      if (navigator.appVersion.indexOf("Mac")!=-1) { 

        // catch slow move towards default Dock position (bottom) 
        if (yFromBottom < 10 && c[c.length - 2].yFromBottom < 15) { vistorIntendsTo = true };

        // catch fast move towards default Dock position (bottom) 
        if ((yFromBottom < 50) 
          && (c[c.length - 1].x === c[c.length - 2].x) 
          && (c[c.length - 1].y === c[c.length - 2].y) 
          && (c[c.length - 1].y === c[c.length - 3].y) 
          && (c[c.length - 1].x === c[c.length - 3].x)) { vistorIntendsTo = true };
      };

      //  catch page inactive state
      if ( document.hidden || document.unloaded ) { vistorIntendsTo = true };

    };

    if (vistorIntendsTo) {
      payload();
      clearInterval(HB.intentInterval);
    };
  },

  initializeIntentListeners: function() {
    HB.intentConditionCache = [];
    // initialize mouse position near center of window, avoids edge case with no mouse events yet
    HB.mouseX = 300;
    HB.mouseY = 300;

    document.onmousemove = function(e) {
      var event = e || window.event;
      HB.mouseX = event.clientX;
      HB.mouseY = event.clientY;
    }
  }

};


/*
CryptoJS v3.1
code.google.com/p/crypto-js
(c) 2009-2013 by Jeff Mott. All rights reserved.
code.google.com/p/crypto-js/wiki/License
*/
// We rename this HBCrypto to prevent namespace collisions
var HBCrypto=HBCrypto||function(a,j){var c={},b=c.lib={},f=function(){},l=b.Base={extend:function(a){f.prototype=this;var d=new f;a&&d.mixIn(a);d.hasOwnProperty("init")||(d.init=function(){d.$super.init.apply(this,arguments)});d.init.prototype=d;d.$super=this;return d},create:function(){var a=this.extend();a.init.apply(a,arguments);return a},init:function(){},mixIn:function(a){for(var d in a)a.hasOwnProperty(d)&&(this[d]=a[d]);a.hasOwnProperty("toString")&&(this.toString=a.toString)},clone:function(){return this.init.prototype.extend(this)}},
u=b.WordArray=l.extend({init:function(a,d){a=this.words=a||[];this.sigBytes=d!=j?d:4*a.length},toString:function(a){return(a||m).stringify(this)},concat:function(a){var d=this.words,M=a.words,e=this.sigBytes;a=a.sigBytes;this.clamp();if(e%4)for(var b=0;b<a;b++)d[e+b>>>2]|=(M[b>>>2]>>>24-8*(b%4)&255)<<24-8*((e+b)%4);else if(65535<M.length)for(b=0;b<a;b+=4)d[e+b>>>2]=M[b>>>2];else d.push.apply(d,M);this.sigBytes+=a;return this},clamp:function(){var D=this.words,d=this.sigBytes;D[d>>>2]&=4294967295<<
32-8*(d%4);D.length=a.ceil(d/4)},clone:function(){var a=l.clone.call(this);a.words=this.words.slice(0);return a},random:function(D){for(var d=[],b=0;b<D;b+=4)d.push(4294967296*a.random()|0);return new u.init(d,D)}}),k=c.enc={},m=k.Hex={stringify:function(a){var d=a.words;a=a.sigBytes;for(var b=[],e=0;e<a;e++){var c=d[e>>>2]>>>24-8*(e%4)&255;b.push((c>>>4).toString(16));b.push((c&15).toString(16))}return b.join("")},parse:function(a){for(var d=a.length,b=[],e=0;e<d;e+=2)b[e>>>3]|=parseInt(a.substr(e,
2),16)<<24-4*(e%8);return new u.init(b,d/2)}},y=k.Latin1={stringify:function(a){var b=a.words;a=a.sigBytes;for(var c=[],e=0;e<a;e++)c.push(String.fromCharCode(b[e>>>2]>>>24-8*(e%4)&255));return c.join("")},parse:function(a){for(var b=a.length,c=[],e=0;e<b;e++)c[e>>>2]|=(a.charCodeAt(e)&255)<<24-8*(e%4);return new u.init(c,b)}},z=k.Utf8={stringify:function(a){try{return decodeURIComponent(escape(y.stringify(a)))}catch(b){throw Error("Malformed UTF-8 data");}},parse:function(a){return y.parse(unescape(encodeURIComponent(a)))}},
x=b.BufferedBlockAlgorithm=l.extend({reset:function(){this._data=new u.init;this._nDataBytes=0},_append:function(a){"string"==typeof a&&(a=z.parse(a));this._data.concat(a);this._nDataBytes+=a.sigBytes},_process:function(b){var d=this._data,c=d.words,e=d.sigBytes,l=this.blockSize,k=e/(4*l),k=b?a.ceil(k):a.max((k|0)-this._minBufferSize,0);b=k*l;e=a.min(4*b,e);if(b){for(var x=0;x<b;x+=l)this._doProcessBlock(c,x);x=c.splice(0,b);d.sigBytes-=e}return new u.init(x,e)},clone:function(){var a=l.clone.call(this);
a._data=this._data.clone();return a},_minBufferSize:0});b.Hasher=x.extend({cfg:l.extend(),init:function(a){this.cfg=this.cfg.extend(a);this.reset()},reset:function(){x.reset.call(this);this._doReset()},update:function(a){this._append(a);this._process();return this},finalize:function(a){a&&this._append(a);return this._doFinalize()},blockSize:16,_createHelper:function(a){return function(b,c){return(new a.init(c)).finalize(b)}},_createHmacHelper:function(a){return function(b,c){return(new ja.HMAC.init(a,
c)).finalize(b)}}});var ja=c.algo={};return c}(Math);
(function(a){var j=HBCrypto,c=j.lib,b=c.Base,f=c.WordArray,j=j.x64={};j.Word=b.extend({init:function(a,b){this.high=a;this.low=b}});j.WordArray=b.extend({init:function(b,c){b=this.words=b||[];this.sigBytes=c!=a?c:8*b.length},toX32:function(){for(var a=this.words,b=a.length,c=[],m=0;m<b;m++){var y=a[m];c.push(y.high);c.push(y.low)}return f.create(c,this.sigBytes)},clone:function(){for(var a=b.clone.call(this),c=a.words=this.words.slice(0),k=c.length,f=0;f<k;f++)c[f]=c[f].clone();return a}})})();
(function(){function a(){return f.create.apply(f,arguments)}for(var j=HBCrypto,c=j.lib.Hasher,b=j.x64,f=b.Word,l=b.WordArray,b=j.algo,u=[a(1116352408,3609767458),a(1899447441,602891725),a(3049323471,3964484399),a(3921009573,2173295548),a(961987163,4081628472),a(1508970993,3053834265),a(2453635748,2937671579),a(2870763221,3664609560),a(3624381080,2734883394),a(310598401,1164996542),a(607225278,1323610764),a(1426881987,3590304994),a(1925078388,4068182383),a(2162078206,991336113),a(2614888103,633803317),
a(3248222580,3479774868),a(3835390401,2666613458),a(4022224774,944711139),a(264347078,2341262773),a(604807628,2007800933),a(770255983,1495990901),a(1249150122,1856431235),a(1555081692,3175218132),a(1996064986,2198950837),a(2554220882,3999719339),a(2821834349,766784016),a(2952996808,2566594879),a(3210313671,3203337956),a(3336571891,1034457026),a(3584528711,2466948901),a(113926993,3758326383),a(338241895,168717936),a(666307205,1188179964),a(773529912,1546045734),a(1294757372,1522805485),a(1396182291,
2643833823),a(1695183700,2343527390),a(1986661051,1014477480),a(2177026350,1206759142),a(2456956037,344077627),a(2730485921,1290863460),a(2820302411,3158454273),a(3259730800,3505952657),a(3345764771,106217008),a(3516065817,3606008344),a(3600352804,1432725776),a(4094571909,1467031594),a(275423344,851169720),a(430227734,3100823752),a(506948616,1363258195),a(659060556,3750685593),a(883997877,3785050280),a(958139571,3318307427),a(1322822218,3812723403),a(1537002063,2003034995),a(1747873779,3602036899),
a(1955562222,1575990012),a(2024104815,1125592928),a(2227730452,2716904306),a(2361852424,442776044),a(2428436474,593698344),a(2756734187,3733110249),a(3204031479,2999351573),a(3329325298,3815920427),a(3391569614,3928383900),a(3515267271,566280711),a(3940187606,3454069534),a(4118630271,4000239992),a(116418474,1914138554),a(174292421,2731055270),a(289380356,3203993006),a(460393269,320620315),a(685471733,587496836),a(852142971,1086792851),a(1017036298,365543100),a(1126000580,2618297676),a(1288033470,
3409855158),a(1501505948,4234509866),a(1607167915,987167468),a(1816402316,1246189591)],k=[],m=0;80>m;m++)k[m]=a();b=b.SHA512=c.extend({_doReset:function(){this._hash=new l.init([new f.init(1779033703,4089235720),new f.init(3144134277,2227873595),new f.init(1013904242,4271175723),new f.init(2773480762,1595750129),new f.init(1359893119,2917565137),new f.init(2600822924,725511199),new f.init(528734635,4215389547),new f.init(1541459225,327033209)])},_doProcessBlock:function(a,b){for(var c=this._hash.words,
f=c[0],j=c[1],d=c[2],l=c[3],e=c[4],m=c[5],N=c[6],c=c[7],aa=f.high,O=f.low,ba=j.high,P=j.low,ca=d.high,Q=d.low,da=l.high,R=l.low,ea=e.high,S=e.low,fa=m.high,T=m.low,ga=N.high,U=N.low,ha=c.high,V=c.low,r=aa,n=O,G=ba,E=P,H=ca,F=Q,Y=da,I=R,s=ea,p=S,W=fa,J=T,X=ga,K=U,Z=ha,L=V,t=0;80>t;t++){var A=k[t];if(16>t)var q=A.high=a[b+2*t]|0,g=A.low=a[b+2*t+1]|0;else{var q=k[t-15],g=q.high,v=q.low,q=(g>>>1|v<<31)^(g>>>8|v<<24)^g>>>7,v=(v>>>1|g<<31)^(v>>>8|g<<24)^(v>>>7|g<<25),C=k[t-2],g=C.high,h=C.low,C=(g>>>19|
h<<13)^(g<<3|h>>>29)^g>>>6,h=(h>>>19|g<<13)^(h<<3|g>>>29)^(h>>>6|g<<26),g=k[t-7],$=g.high,B=k[t-16],w=B.high,B=B.low,g=v+g.low,q=q+$+(g>>>0<v>>>0?1:0),g=g+h,q=q+C+(g>>>0<h>>>0?1:0),g=g+B,q=q+w+(g>>>0<B>>>0?1:0);A.high=q;A.low=g}var $=s&W^~s&X,B=p&J^~p&K,A=r&G^r&H^G&H,ka=n&E^n&F^E&F,v=(r>>>28|n<<4)^(r<<30|n>>>2)^(r<<25|n>>>7),C=(n>>>28|r<<4)^(n<<30|r>>>2)^(n<<25|r>>>7),h=u[t],la=h.high,ia=h.low,h=L+((p>>>14|s<<18)^(p>>>18|s<<14)^(p<<23|s>>>9)),w=Z+((s>>>14|p<<18)^(s>>>18|p<<14)^(s<<23|p>>>9))+(h>>>
0<L>>>0?1:0),h=h+B,w=w+$+(h>>>0<B>>>0?1:0),h=h+ia,w=w+la+(h>>>0<ia>>>0?1:0),h=h+g,w=w+q+(h>>>0<g>>>0?1:0),g=C+ka,A=v+A+(g>>>0<C>>>0?1:0),Z=X,L=K,X=W,K=J,W=s,J=p,p=I+h|0,s=Y+w+(p>>>0<I>>>0?1:0)|0,Y=H,I=F,H=G,F=E,G=r,E=n,n=h+g|0,r=w+A+(n>>>0<h>>>0?1:0)|0}O=f.low=O+n;f.high=aa+r+(O>>>0<n>>>0?1:0);P=j.low=P+E;j.high=ba+G+(P>>>0<E>>>0?1:0);Q=d.low=Q+F;d.high=ca+H+(Q>>>0<F>>>0?1:0);R=l.low=R+I;l.high=da+Y+(R>>>0<I>>>0?1:0);S=e.low=S+p;e.high=ea+s+(S>>>0<p>>>0?1:0);T=m.low=T+J;m.high=fa+W+(T>>>0<J>>>0?1:
0);U=N.low=U+K;N.high=ga+X+(U>>>0<K>>>0?1:0);V=c.low=V+L;c.high=ha+Z+(V>>>0<L>>>0?1:0)},_doFinalize:function(){var a=this._data,b=a.words,c=8*this._nDataBytes,f=8*a.sigBytes;b[f>>>5]|=128<<24-f%32;b[(f+128>>>10<<5)+30]=Math.floor(c/4294967296);b[(f+128>>>10<<5)+31]=c;a.sigBytes=4*b.length;this._process();return this._hash.toX32()},clone:function(){var a=c.clone.call(this);a._hash=this._hash.clone();return a},blockSize:32});j.SHA512=c._createHelper(b);j.HmacSHA512=c._createHmacHelper(b)})();
(function(){var a=HBCrypto,j=a.enc.Utf8;a.algo.HMAC=a.lib.Base.extend({init:function(a,b){a=this._hasher=new a.init;"string"==typeof b&&(b=j.parse(b));var f=a.blockSize,l=4*f;b.sigBytes>l&&(b=a.finalize(b));b.clamp();for(var u=this._oKey=b.clone(),k=this._iKey=b.clone(),m=u.words,y=k.words,z=0;z<f;z++)m[z]^=1549556828,y[z]^=909522486;u.sigBytes=k.sigBytes=l;this.reset()},reset:function(){var a=this._hasher;a.reset();a.update(this._iKey)},update:function(a){this._hasher.update(a);return this},finalize:function(a){var b=
this._hasher;a=b.finalize(a);b.reset();return b.finalize(this._oKey.clone().concat(a))}})})();
(function(){var k=HBCrypto,b=k.lib,m=b.WordArray,l=b.Hasher,d=[],b=k.algo.SHA1=l.extend({_doReset:function(){this._hash=new m.init([1732584193,4023233417,2562383102,271733878,3285377520])},_doProcessBlock:function(n,p){for(var a=this._hash.words,e=a[0],f=a[1],h=a[2],j=a[3],b=a[4],c=0;80>c;c++){if(16>c)d[c]=n[p+c]|0;else{var g=d[c-3]^d[c-8]^d[c-14]^d[c-16];d[c]=g<<1|g>>>31}g=(e<<5|e>>>27)+b+d[c];g=20>c?g+((f&h|~f&j)+1518500249):40>c?g+((f^h^j)+1859775393):60>c?g+((f&h|f&j|h&j)-1894007588):g+((f^h^
j)-899497514);b=j;j=h;h=f<<30|f>>>2;f=e;e=g}a[0]=a[0]+e|0;a[1]=a[1]+f|0;a[2]=a[2]+h|0;a[3]=a[3]+j|0;a[4]=a[4]+b|0},_doFinalize:function(){var b=this._data,d=b.words,a=8*this._nDataBytes,e=8*b.sigBytes;d[e>>>5]|=128<<24-e%32;d[(e+64>>>9<<4)+14]=Math.floor(a/4294967296);d[(e+64>>>9<<4)+15]=a;b.sigBytes=4*d.length;this._process();return this._hash},clone:function(){var b=l.clone.call(this);b._hash=this._hash.clone();return b}});k.SHA1=l._createHelper(b);k.HmacSHA1=l._createHmacHelper(b)})();
