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
if (typeof(_hbq) == 'undefined'){_hbq=[];}
var HBQ = function()
{
  // Initialize the rules array so it can be pushed into
  HB.rules = [];
  // Need to load the serialized cookies
  HB.loadCookies();
  // Once initialized replace the existing data with it
  if(typeof(_hbq) != "undefined" && _hbq && _hbq.length)
  {
    for(var i=0;i<_hbq.length;i++)
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
    if (containerDocument) {
      HB.e.siteElement = containerDocument.getElementById("hellobar");
      HB.e.shadow = containerDocument.getElementById("hellobar-shadow");
    }
    // Monitor siteElement height to update HTML/CSS
    if ( HB.e.siteElement )
    {
      if ( HB.e.siteElement.clientHeight )
      {
        // Adjust the shadow offset
        if ( HB.e.shadow ) {
          HB.e.shadow.style.top = (HB.e.siteElement.clientHeight+(HB.currentSiteElement.show_border ? 0 : -1))+"px";
          HB.e.shadow.style.display = "block";
        }
        // Adjust the container height
        if ( HB.e.container )
          HB.e.container.style.height = (HB.e.siteElement.clientHeight+8)+"px"; 
        // Adjust the pusher
        if ( HB.e.pusher )
          HB.e.pusher.style.height = (HB.e.siteElement.clientHeight+(HB.t(HB.currentSiteElement.show_border) ? 3 : 0))+"px";
        // Add multiline class
        if ( HB.e.siteElement.clientHeight > 50 ) {
          HB.addClass(HB.e.siteElement, "multiline");
        } else {
          HB.removeClass(HB.e.siteElement, "multiline");
        }
      }

      // Update the CSS class based on the width
      var origValue = HB.isMobileWidth;
      HB.isMobileWidth = (HB.e.siteElement.clientWidth <= 640 );
      if ( origValue == HB.isMobileWidth )
        return;
      if ( HB.isMobileWidth )
        HB.addClass(HB.e.siteElement, "mobile");
      else
        HB.removeClass(HB.e.siteElement, "mobile");
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
    if ( !HB.css )
      HB.css = "";
    HB.css += "<style>"+css+"</style>";
  },

  // Normalizes a URL so that "https://www.google.com/#foo" becomes "http://google.com"
  // Also sorts the params alphabetically
  n: function(url, pathOnly)
  {
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

  // Returns the standard siteElement params used for communicating with the backend server
  attributeParams: function()
  {
    return "a="+encodeURIComponent("all:all|"+HB.serializeCookies(HB.cookies));
  },

  // Sends data to the tracking server (e.g. which siteElements viewed, if a rule was performed, etc)
  s: function(url, paramString, callback)
  {
    if ( typeof(HB_DNT) != "undefined" || typeof(HB_SITE_ID) == "undefined")
    {
      if ( callback && typeof(callback) == "function" )
        callback();
      return;
    }
    var img = document.createElement('img');
    img.style.display = 'none';
    // Standard params
    url += ((url.indexOf("?") == -1) ? "?" : "&") + "s="+HB_SITE_ID+"&u="+HB.i();
    // Extra params
    if ( paramString )
      url += ((paramString.indexOf("&") == 0) ? "" : "&") + paramString;
    // Make sure we return an image
    url += "&t=i";

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

  // Gets data from the tracking server such as what siteElement variation to render from a set of siteElements
  g: function(url, paramString, callback)
  {
    var script = document.createElement('script');
    script.type = "text/javascript";
    script.async = true;
    // Standard params
    url += ((url.indexOf("?") == -1) ? "?" : "&") + "s="+HB_SITE_ID+"&u="+HB.i();
    // Extra params
    if ( paramString )
      url += ((paramString.indexOf("&") == 0) ? "" : "&") + paramString;
    // Make sure we return Javascript 
    url += "&t=j"; 
    if ( callback )
    {
      // Create a new function that can be referenced in the global name space
      if (!HB.cb)
        HB.cb = [];
      var responderName = "HB.cb["+(HB.cb.length)+"]";
      // Add the responder name to the request
      url += "&j="+encodeURIComponent(responderName);
      // Make sure you only call the callback once
      // We do this by setting a locally scoped variable, issuedCallback
      var issuedCallback = false;
      var issueCallback = function(result){
        if( !issuedCallback)
          callback(result);
        issuedCallback = true;
      };
      // Set the global responder to issue the callback
      HB.cb.push(function(result){
        issueCallback(result);
      });
      // Call the callback within a set period of time in case the server
      // does not respond - notice that result will be null and a subsequent
      // response will be ignored
      setTimeout(issueCallback, 750);
    }
    script.src = HB.hi(url);
    // Insert the script
    (document.head || document.body || document.childNodes[0]).appendChild(script);
  },

  // Returns the URL for the backend server (e.g. "hi.hellobar.com").
  hi: function(url)
  {
    return (document.location.protocol == "https:" ? "https" : "http")+ "://"+HB_BACKEND_HOST+"/"+url;
  },

  // Recoards the rule being formed when the visitor clicks the specified element
  trackClick: function(element)
  {
    var url = element.href;
    HB.converted(function(){element.target == "_blank" ?  window.open(url) : document.location = url;});
  },

  // Returns the conversion key used in the cookies to determine if this
  // conversion has already happened or not
  getConversionKey: function(siteElement)
  {
    switch(HB.baseType(siteElement))
    {
      case "email":
        return "ec";
      case "social":
        return "sc";
      case "link":
        // Need to make sure this is unique per URL
        // getShortestKey returns either the raw URL or
        // a SHA1 hash of the URL - whichever is shorter
        return "l-"+HB.getShortestKeyForURL(siteElement.url);
    }
  },

  // Returns the base type for a site element. Will be either:
  // email, social, or link
  baseType: function(siteElement)
  {
    switch(siteElement.type)
    {
      case "facebook":
      case "twitter":
        return "social";
    }

    // Just return the type
    return siteElement.type;
  },

  // Returns the shortest possible key for the given URL,
  // which may be a SHA1 hash of the url
  getShortestKeyForURL: function(url)
  {
    // If the URL is on the same domain strip it to the path
    // If the URL is shorter than 40 chars just return it
    // Otherwise return a SHA1 hash of the URL
  },

  // Called when a conversion happens (e.g. link clicked, email form filled out)
  converted: function(callback)
  {
    var conversionKey = HB.getConversionKey(HB.currentSiteElement);
    var conversionData = HB.getVisitorData(conversionKey);
    var now = Math.round(new Date().getTime()/1000)
    if ( !conversionData )
      conversionData = [now, now, 0];

    // We store first time converted, last time converted and number of conversions
      
    conversionData[1] = now; // Set the last time they converted to now
    conversionData[2] += 1; // Increase number of times
    HB.setVisitorData(conversionKey, conversionData);
    HB.setSiteElementData(HB.si, "nc", (HB.getSiteElementData(HB.si, "nc") || 0)+1);
    HB.setSiteElementData(HB.si, "nc", (HB.getSiteElementData(HB.si, "nc") || 0)+1);
    if ( !HB.getSiteElementData(HB.si, "fc") )
      HB.setSiteElementData(HB.si, "fc", now);
    HB.setSiteElementData(HB.si, "lc", now);
    HB.trigger("conversion", HB.currentSiteElement);
    HB.s("c?b="+HB.si, HB.attributeParams(), callback);
  },

  // Returns true if the visitor did this conversion or not
  didConvert: function(siteElement)
  {
    return HB.getVisitorData(HB.getConversionKey(HB.currentSiteElement));
  },

  // This takes the the email field, name field, and target siteElement DOM element.
  // It then checks the validity of the fields and if valid it records the 
  // email and then sets the message in the siteElement to "Thank you". If invalid it
  // shakes the email field
  submitEmail: function(emailField, nameField, targetSiteElement)
  {
    HB.validateEmail(
      emailField.value,
      nameField.value,
      function(){
        targetSiteElement.innerHTML='<span>Thank you!</span>';
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
    if ( email && email.match(/.+@.+\..+/) )
      successCallback();
    else
      failCallback();
  },

  // Called to record an email for the rule without validation (also used by submitEmail)
  recordEmail: function(email, name, callback)
  {
    if ( email )
    {
      var params = ["g="+HB.cli, "e="+encodeURIComponent(email)];
      if ( name )
        params.push("n="+encodeURIComponent(name));

      params.push("q=y"); // only in staging

      // Record the email address and then track that the rule was performed
      HB.s("e", params.join("&"), function(){HB.converted(callback)});
    }

  },
  // Serialzied the cookies object into a string that can be stored in a cookie. The 
  // cookies object should be in the form:
  // {
  //   siteElements: {
  //     site_element_id: {
  //       first_view: timestamp,
  //       last_view: timestamp,
  //       num_views: count,
  //       first_action: timestamp,
  //       last_action: timestamp,
  //       num_actions: count,
  //       *custom: *value
  //     }
  //   },
  //   visitor: {
  //     first_visit: timestamp,
  //     last_visit: timestamp,
  //     num_visits: count,
  //     *custom: *value
  //   }
  // }
  serializeCookies: function(cookies)
  {
    if ( !cookies )
      return "";
    var result = "";
    if ( cookies.visitor )
    {
      result += HB.serializeCookieValues(cookies.visitor);
    }
    result += "^";
    if ( cookies.siteElements )
    {
      for(var siteElementID in cookies.siteElements)
      {
        result += siteElementID+"|"+HB.serializeCookieValues(cookies.siteElements[siteElementID])+"^";
      }
    }
    return result;
  },

  // Called by serializeCookies. Takes a hash (either visitor or siteElement) and
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

  // Parses a cookie string into the object describe in serializeCookies
  parseCookies: function(input)
  {
    var results = {};
    if ( !input )
      return {visitor:{}, siteElements:{}};
    var parts = input.split("^");

    // Parse out the visitor uwhich is the first argument
    results.visitor = HB.parseCookieValues(parts[0]);
    // Parse out all the siteElements
    results.siteElements = {};
    for(var i=1;i<parts.length;i++)
    {
      if ( parts[i] ) // Ignore empty parts
      {
        var siteElementData = parts[i].split("|");
        var siteElementID = siteElementData[0];
        var siteElementValues = siteElementData.slice(1, siteElementData.length);

        results.siteElements[siteElementID] = HB.parseCookieValues(siteElementValues.join("|"));
      }
    }
    return results;
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

      // Convert value to a number if it makes sense
      if ( parseInt(value, 10) == value )
          value = parseInt(value,10);
      else if ( parseFloat(value) == value )
          value = parseFloat(value);
      results[key] = value;
    }
    return results;
  },

  // Loads the cookies from the browser cookies into global hash HB.cookies
  // in the format of {siteElements: {id:{...}, id2:{...}}, visitor:{...}}
  loadCookies: function()
  {
    // Don't let any cookies get set without a site ID
    if ( typeof(HB_SITE_ID) == "undefined")
      HB.cookies = {siteElements:{}, visitor:{}};
    else
      HB.cookies = HB.parseCookies(HB.gc("hb_"+HB_SITE_ID));
  },

  // Saves HB.cookies into the actual cookie
  saveCookies: function()
  {
    // Don't let any cookies get set without a site ID
    if ( typeof(HB_SITE_ID) != "undefined")
      HB.sc("hb_"+HB_SITE_ID, HB.serializeCookies(HB.cookies), 365*5);
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
    // Ensure siteElementID is a string
    siteElementID = siteElementID+"";
    if ( !HB.cookies.siteElements[siteElementID] )
      return null;
    return HB.cookies.siteElements[siteElementID][key];
  },

  // Sets the siteElement attribute specified by the key and siteElementID to the value in HB.cookies
  // Also updates the cookies via HB.saveCookies
  setSiteElementData: function(siteElementID, key, value)
  {
    // Ensure siteElementID is a string
    siteElementID = siteElementID+"";
    if ( !HB.cookies.siteElements[siteElementID] )
      HB.cookies.siteElements[siteElementID] = {};
    HB.cookies.siteElements[siteElementID][key] = value;
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

  // Called before rendering. This lets you modify siteElement attributes.
  // NOTE: siteElement is already a copy of the original siteElement so it can be 
  // safely modified.
  prerender: function(siteElement)
  {
    return this.sanitize(siteElement);
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
    var siteElementCopy = {};
    // Make a copy of the siteElement
    for(var k in siteElementToRender)
    {
      siteElementCopy[k] = siteElementToRender[k];
    }
    // Call prerender
    var siteElement = HB.prerender(siteElementCopy);
    HB.currentSiteElement = siteElement;
    HB.si = siteElement.id;
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
        // Track the view
        HB.viewed();
        // Monitor zoom scale events
        HB.hideOnZoom();
      }, 1);
    });
  },

  // Called when the siteElement is viewed
  viewed: function()
  {
    // Track number of views
    HB.s("v?b="+HB.si, HB.attributeParams());
    // Record the number of views, first seen and last seen
    HB.setSiteElementData(HB.si, "nv", (HB.getSiteElementData(HB.si, "nv") || 0)+1);
    var now = Math.round(nowDate.getTime()/1000);
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
  injectAtTop:function(element)
  {
    if ( document.body.children[0] )
      document.body.insertBefore(element,document.body.children[0]);
    else
      document.body.appendChild(element);
  },

  // Injects the specified HTML for the given siteElement into the page
  injectSiteElementHTML: function(html, siteElement)
  {
    // Remove the containing iframe element if it exists
    if ( HB.w )
      HB.w.parentNode.removeChild(HB.w);
    // Create the iframe container
    HB.w = document.createElement("iframe");
    HB.w.src = "about:blank";
    HB.w.id = "hellobar_container";
    HB.w.name = "hellobar_container";
    // Set any necessary CSS classes
    HB.w.className = siteElement.size+(HB.t(siteElement.remains_at_top) ? " remains_at_top" : "");
    HB.w.scrolling = "no";
    // Remove the pusher if it exists
    if ( HB.p )
      HB.p.parentNode.removeChild(HB.p);
    HB.p = null;
    // Create the pusher (which pushes the page down) if needed
    if ( HB.t(siteElement.pushes_page_down) )
    {
      HB.p = document.createElement("div");
      HB.p.id="hellobar_pusher";
      HB.p.className = siteElement.size;
      HB.injectAtTop(HB.p);
    }
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
    var d = HB.w.siteElementWindow.document;
    d.open();
    d.write((HB.css || "")+html);
    d.close();
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
        for(j=0;j<rule.site_elements.length;j++)
        {
          siteElement = rule.site_elements[j];
          if ( !HB.didConvert(siteElement) )
          {
            var type = HB.baseType(siteElement);
            if ( !possibleSiteElements[type] )
              possibleSiteElements[type] = [];
            possibleSiteElements[type].push(siteElement);
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
    else if ( possibleSiteElements.link )
      possibleSiteElements = possibleSiteElements.link;
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
        if (a.conversionRate < b.conversionRate)
          return 1;
        else if (a.conversionRate > b.conversionRate)
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
        if ( rule.match == "any" )
          return true;
      }
      else
      {
        // We didn't match a condition. Return false if we needed to
        // match all of them
        if ( rule.match == "all" )
          return false;
      }
    }
    // If we needed to match any condition (and we had at least one)
    // and didn't yet return false
    if ( rule.match == "any" && rule.conditions.length > 0)
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
    return HB.applyOperand(currentValue, condition.operand, condition.value);
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
      return (new Date()); // special case

    // All other segment names
    return HB.getVisitorData(segmentName);
  },

  // Applies the operand specified to the arguments passed in
  applyOperand: function(a, operand, b)
  {
    switch(operand)
    {
      case "is":
        return HB.guessType(a, [b]) == HB.guessType(b, a);
      case "is_not":
        return HB.guessType(a, [b]) != HB.guessType(b, a);
      case "includes":
        return HB.stringify(a).indexOf(HB.stringify(b)) != -1;
      case "does_not_include":
        return HB.stringify(a).indexOf(HB.stringify(b)) == -1;
      case "before":
      case "less_than":
        return HB.numerify(a) < HB.numerify(b);
      case "less_than_or_equal":
        return HB.numerify(a) <= HB.numerify(b);
      case "after":
      case "greater_than":
        return HB.numerify(a) > HB.numerify(b);
      case "greater_than_or_equal":
        return HB.numerify(a) >= HB.numerify(b);
      case "between":
        return HB.numerify(a) >= HB.numerify(b[0]) && HB.numerify(a) <= HB.numerify(b[1]);
    }
  },

  // Returns a normalized string value
  // Used for applying operands
  stringify: function(o)
  {
    return (o+"").toLowerCase();
  },

  // Turns the input into a number. If this is a date reference it
  // will be converted into a timestamp
  // Used for applying operands
  numerify: function(o)
  {
    return Number(o);
  },

  // This guesses the type. If it is numeric or a date reference it will
  // use "numerify", otherwise it will use "stringify".
  // Used for applying operands
  guessType: function(o)
  {
    return HB.stringify(o);
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
        // Set the full referrer
        HB.setVisitorData("rf", referrer);
        // Set the referrer domain
        HB.setVisitorData("rd", referrerDomain);

        // Check for search terms
        var referrerQueryParts = referrer.split("?")[1];
        if ( referrerQueryParts )
        {
          // Build a hash of decoded params;
          var params = {};
          var pairs = referrerQueryParts.split("&");
          for(var i=0;i<pairs.length;i++)
          {
            var key, value;
            var components = pairs[i].split("=");
            key = decodeURIComponent(components[0]).toLowerCase();
            value = decodeURIComponent(components[1]);
            params[key] = value;
          }

          // Check for search terms
          var search = params['query'] || params['q'] || params['search'];
          if ( search )
            HB.setVisitorData("st", search);
          // Check for UTM variables and set them if present
          HB.setVisitorData('ad_so', params['utm_source'], true);
          HB.setVisitorData('ad_ca', params['utm_campaign'], true);
          HB.setVisitorData('ad_me', params['utm_medium'], true);
          HB.setVisitorData('ad_co', params['utm_siteElement'], true);
          HB.setVisitorData('ad_te', params['utm_term'], true);
        }
      }
    }
    // Set the page URL
    HB.setVisitorData("pu", (document.location+"").split("#")[0]);
    // Set the date
    HB.setVisitorData("dt", nowDate.getUTCFullYear()+"-"+(nowDate.getUTCMonth()+1)+"-"+nowDate.getUTCDate());
    // Set the timestamp - this can be used for filtering
    HB.setVisitorData("ts", now);

    // Detect the device
    var ua = navigator.userAgent;
    if (ua.match(/(mobi|phone|ipod|blackberry|docomo)/i))
      HB.setVisitorData("dv", "mobile");
    else if (ua.match(/(ipad|kindle|android)/i))
      HB.setVisitorData("dv", "tablet");
    else
      HB.setVisitorData("dv", "computer");
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

  // Returns UTC time (you must ignore the timezone attached, as it will be local)
  utc: function() {
    var now = new Date();
    return new Date(now.getUTCFullYear(),
                    now.getUTCMonth(),
                    now.getUTCDate(),
                    now.getUTCHours(),
                    now.getUTCMinutes(),
                    now.getUTCSeconds());
  },

  // Returns time at International Date Line cross (i.e. the first second it is a new day, or UTC+12 hours).
  idl: function() {
    return new Date(this.utc().getTime() + ((86400/2) * 1000));
  },

  // Returns current date as YYYY/MM/DD +ZZ:ZZ, which is lexicographically sortable.
  // ZZ:ZZ refers to the offset from the International Date line, but inverted.
  // The latest time zones (Hawaii, for example) have the smallest offset,
  // so they are always less than the later timezones.
  //
  // Generally, UTC is +-0. Here, UTC is +12.00. To find a TZ's offset under these rules, add 12.
  // Chicago would be +06:00 (outside of DST, when it is +07:00).
  // SF is +04:00 (+05:00 in DST).
  // Half hour time zones would be +05:30.
  //
  // Passing no argument leads to "Detect visitor timezone" mode, as does "auto".
  // Pass an integer offset in hours otherwise, from 0 to 23.
  comparableDate: function(targetOffset) {
    if (typeof targetOffset === "undefined") targetOffset = "auto";
    if (targetOffset === "auto") {
      return this.ymd(new Date());
    } else {
      var idl = this.idl(),
          time = new Date();

      targetOffset *= 60; // We're working with minutes in this function

      var baseOffset = time.getTimezoneOffset();

      var offsetMS = (targetOffset - baseOffset) * 60000;

      convertedTime = new Date(this.utc().getTime() + offsetMS);
      
      return this.ymd(idl) + " +" + this.zeropad(convertedTime.getHours()) + ":" + this.zeropad(convertedTime.getMinutes());
    }
  },

  ymd: function(date) {
    if (typeof date === "undefined") date = new Date();
    var m = date.getMonth() + 1;
    return date.getFullYear() + "/" + this.zeropad(m) + "/" + this.zeropad(date.getDate());
  },

  // Copied from zeropad.jquery.js
  zeropad: function(string, length) {
    // default to 2
    string = string.toString();
    if (typeof length === "undefined" && string.length == 1) length = 2;
    length = length || string.length;
    return string.length >= length ? string : this.zeropad("0" + string, length);
  }
};
