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
  HB.applyRules();
  
  // As the user readjust the window size we need to adjust the size of the containing
  // iframe. We do this by checking the the size of the inner div. If the the width
  // of the window is less than or equal to 640 pixels we set the flag isMobileWidth to true.
  // Note: we are not actually detecting a mobile device - just the width of the window. 
  // If isMobileWidth is true we add an additional "mobile" CSS class which is used to 
  // adjust the style of the content.
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
      HB.e.content = containerDocument.getElementById("hellobar");
      HB.e.shadow = containerDocument.getElementById("hellobar-shadow");
    }
    // Monitor content height to update HTML/CSS
    if ( HB.e.content )
    {
      if ( HB.e.content.clientHeight )
      {
        // Adjust the shadow offset
        if ( HB.e.shadow ) {
          HB.e.shadow.style.top = (HB.e.content.clientHeight+(HB.currentContent.show_border ? 0 : -1))+"px";
          HB.e.shadow.style.display = "block";
        }
        // Adjust the container height
        if ( HB.e.container )
          HB.e.container.style.height = (HB.e.content.clientHeight+8)+"px"; 
        // Adjust the pusher
        if ( HB.e.pusher )
          HB.e.pusher.style.height = (HB.e.content.clientHeight+(HB.t(HB.currentContent.show_border) ? 3 : 0))+"px";
        // Add multiline class
        if ( HB.e.content.clientHeight > 50 ) {
          HB.addClass(HB.e.content, "multiline");
        } else {
          HB.removeClass(HB.e.content, "multiline");
        }
      }

      // Update the CSS class based on the width
      var origValue = HB.isMobileWidth;
      HB.isMobileWidth = (HB.e.content.clientWidth <= 640 );
      if ( origValue == HB.isMobileWidth )
        return;
      if ( HB.isMobileWidth )
        HB.addClass(HB.e.content, "mobile");
      else
        HB.removeClass(HB.e.content, "mobile");
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
// **Special case: If a user includes multiple contentItems, to avoid overwriting the first content and causing errors,
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

  // Returns the standard content params used for communicating with the backend server
  attributeParams: function()
  {
    return "a="+encodeURIComponent("all:all|"+HB.serializeCookies(HB.cookies));
  },

  // Sends data to the tracking server (e.g. which contentItems viewed, if a rule was performed, etc)
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

  // Gets data from the tracking server such as what content variation to render from a set of contentItems
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
    HB.conversion(function(){element.target == "_blank" ?  window.open(url) : document.location = url;});
  },

  // Returns the conversion key used in the cookies to determine if this
  // conversion has already happened or not
  getConversionKey: function(content)
  {
    switch(content.type)
    {
      case "email":
        return "ec";
      case "social-facebook-like":
        return "fl";
      case "link":
        // Need to make sure this is unique per URL
        // getShortestKey returns either the raw URL or
        // a SHA1 hash of the URL - whichever is shorter
        return "l-"+HB.getShortestKeyForURL(content.url);
    }
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
  conversion: function(callback)
  {
    var conversion_Key = HB.getConversionKey(HB.currentContent);
    HB.setUserData(conversionKey, (HB.getUserData(conversionKey) || 0)+1);
    HB.trigger("conversion", HB.currentContent);
    HB.s("c?b="+HB.bi, HB.attributeParams(), callback);
  },

  // This takes the the email field, name field, and target content DOM element.
  // It then checks the validity of the fields and if valid it records the 
  // email and then sets the message in the content to "Thank you". If invalid it
  // shakes the email field
  submitEmail: function(emailField, nameField, targetContent)
  {
    HB.validateEmail(
      emailField.value,
      nameField.value,
      function(){
        targetContent.innerHTML='<span>Thank you!</span>';
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
      HB.s("e", params.join("&"), function(){HB.conversion(callback)});
    }

  },
  // Serialzied the cookies object into a string that can be stored in a cookie. The 
  // cookies object should be in the form:
  // {
  //   contentItems: {
  //     content_id: {
  //       first_view: timestamp,
  //       last_view: timestamp,
  //       num_views: count,
  //       first_action: timestamp,
  //       last_action: timestamp,
  //       num_actions: count,
  //       *custom: *value
  //     }
  //   },
  //   user: {
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
    if ( cookies.user )
    {
      result += HB.serializeCookieValues(cookies.user);
    }
    result += "^";
    if ( cookies.contentItems )
    {
      for(var contentID in cookies.contentItems)
      {
        result += contentID+"|"+HB.serializeCookieValues(cookies.contentItems[contentID])+"^";
      }
    }
    return result;
  },

  // Called by serializeCookies. Takes a hash (either user or content) and
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
        pairs.push(HB.sanitizeCookieValue(key)+":"+HB.sanitizeCookieValue(value));
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
      return {user:{}, contentItems:{}};
    var parts = input.split("^");

    // Parse out the user uwhich is the first argument
    results.user = HB.parseCookieValues(parts[0]);
    // Parse out all the contentItems
    results.contentItems = {};
    for(var i=1;i<parts.length;i++)
    {
      if ( parts[i] ) // Ignore empty parts
      {
        var contentData = parts[i].split("|");
        var contentID = contentData[0];
        var contentValues = contentData.slice(1, contentData.length);

        results.contentItems[contentID] = HB.parseCookieValues(contentValues.join("|"));
      }
    }
    return results;
  },

  // Called by parseCookies. Takes a string (either user or content) and
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
  // in the format of {contentItems: {id:{...}, id2:{...}}, user:{...}}
  loadCookies: function()
  {
    // Don't let any cookies get set without a site ID
    if ( typeof(HB_SITE_ID) == "undefined")
      HB.cookies = {contentItems:{}, user:{}};
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

  // Gets the user attribute specified by the key or returns null
  getUserData: function(key)
  {
    return HB.cookies.user[key];
  },

  // Sets the user attribute specified by the key to the value in the HB.cookies hash
  // Also updates the cookies via HB.saveCookies
  setUserData: function(key, value, skipEmptyValue)
  {
    if ( skipEmptyValue && !value) // This allows us to only conditionally set values
      return;
    HB.cookies.user[key] = value;
    HB.saveCookies();
  },

  // Gets the content attribute from HB.cookies specified by the contentID and key
  getContentData: function(contentID, key)
  {
    // Ensure contentID is a string
    contentID = contentID+"";
    if ( !HB.cookies.contentItems[contentID] )
      return null;
    return HB.cookies.contentItems[contentID][key];
  },

  // Sets the content attribute specified by the key and contentID to the value in HB.cookies
  // Also updates the cookies via HB.saveCookies
  setContentData: function(contentID, key, value)
  {
    // Ensure contentID is a string
    contentID = contentID+"";
    if ( !HB.cookies.contentItems[contentID] )
      HB.cookies.contentItems[contentID] = {};
    HB.cookies.contentItems[contentID][key] = value;
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

  // Returns the template HTML for the given content. Most of the time the same
  // template will be returned for the same content. The values in {{}} are replaced with
  // the values from the content
  //
  // By default this just returns the HB.templateHTML variable for the given rule type
  getTemplate: function(content)
  {
    return HB.templateHTML[content.template_name];
  },

  // Called before rendering. This lets you modify content attributes.
  // NOTE: content is already a copy of the original content so it can be 
  // safely modified.
  prerender: function(content)
  {
    return this.sanitize(content);
  },

  // Takes each string value in the content and escapes HTML < > chars
  // with the matching symbol
  sanitize: function(content){
    for (var k in content){
      if (content.hasOwnProperty(k) && content[k] && content[k].replace)
        content[k] = content[k].replace(/</g,'&lt;').replace(/>/g,'&gt;');
    }
    return content;
  },

  // Renders the html template for the content by calling HB.parseTemplateVar for
  // each {{...}} entry in the template
  renderTemplate: function(html, content)
  {
    return html.replace(/\{\{(.*?)\}\}/g, function(match, value){
      return HB.parseTemplateVar(value, content);
    });
  },

  // Parses the value passed in in {{...}} for a template (which basically does an eval on it)
  parseTemplateVar: function(value, content)
  {
    try{value = eval(value)}catch(e){}
    return (value === undefined ? "" : value);
  },

  // This lets users set a callback for a Hello Bar event specified by eventName (e.g. "contentItemshown")
  on: function(eventName, callback)
  {
    if (!HB.eventCallbacks)
      HB.eventCallbacks = {};
    if ( !HB.eventCallbacks[eventName] )
      HB.eventCallbacks[eventName] = [];
    HB.eventCallbacks[eventName].push(callback);
  },

  // This is called internally to trigger a Hello Bar event (e.g. "contentItemshown")
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
  
  // Renders the content
  render: function(contentToRender)
  {
    var contentCopy = {};
    // Make a copy of the content
    for(var k in contentToRender)
    {
      contentCopy[k] = contentToRender[k];
    }
    // Call prerender
    var content = HB.prerender(contentCopy);
    HB.currentContent = content;
    HB.bi = content.id;
    // If there is a #nohb in the has we don't render anything
    if ( document.location.hash == "#nohb" )
      return;
    // Replace all the templated variables
    var html = HB.renderTemplate(this.getTemplate(content)+"", content);
    // Once the dom is ready we inject the html returned from renderTemplate
    HB.domReady(function(){
      // Set an arbitrary timeout to prevent some rendering
      // conflicts with certain sites
      setTimeout(function(){
        HB.injectContentHTML(html, content);
        // Track the view
        HB.viewed();
        // Monitor zoom scale events
        HB.hideOnZoom();
      }, 1);
    });
  },

  // Called when the content is viewed
  viewed: function()
  {
    // Track number of views
    HB.s("v?b="+HB.bi, HB.attributeParams());
    // Trigger content shown event
    HB.trigger("contentItemshown", HB.currentContent);
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

  // Injects the specified HTML for the given content into the page
  injectContentHTML: function(html, content)
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
    HB.w.className = content.size+(HB.t(content.remains_at_top) ? " remains_at_top" : "");
    HB.w.scrolling = "no";
    // Remove the pusher if it exists
    if ( HB.p )
      HB.p.parentNode.removeChild(HB.p);
    HB.p = null;
    // Create the pusher (which pushes the page down) if needed
    if ( HB.t(content.pushes_page_down) )
    {
      HB.p = document.createElement("div");
      HB.p.id="hellobar_pusher";
      HB.p.className = content.size;
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
    // Render the content in the container.
    var d = HB.w.contentWindow.document;
    d.open();
    d.write((HB.css || "")+html);
    d.close();
  },

  // Adds a rule to the list of rules. The method is a function that returns true if the given
  // visitor is eligible for the rule. The contentItems is the list of contentItems for the given rule. Priority
  // is a numeric value and metadata is a hash of settings for the rule.
  addRule: function(method, contentItems, priority, metadata)
  {
    // First check to see if contentItems is an array, and make it one if it is not
    if (Object.prototype.toString.call(contentItems) !== "[object Array]")
      contentItems = [contentItems];
    if ( !priority )
      priority = 0;
    // Create the rule
    var rule = {method: method, contentItems: contentItems, priority: priority, data: metadata};
    HB.rules.push(rule);
    // Set the rule on all of the contentItems
    for(var i=0;i<contentItems.length;i++)
    {
      contentItems[i].rule = rule;
    }
  },

  // applyRules scans through all the rules added via addRule and finds the
  // highest priority rule the visitor is eligible for. Once found it sends
  // all the eligible contentItems to the backend server which then returns with which
  // variation to show.
  applyRules: function()
  {
    // Sort the rules
    HB.rules.sort(function(a,b){
      if ( a.priority > b.priority )
        return 1;
      else if ( a.priority < b.priority )
        return -1;
      else
        return 0;
    });
    // Determine the first rule the visitor is eligible for
    for(var i=0;i<HB.rules.length;i++)
    {
      var rule = HB.rules[i];
      if ( rule.method() ) // Did the method return true?
      {
        // Found a match
        // If there is content then render it
        if ( rule.contentItems && rule.contentItems.length > 0 && rule.contentItems[0])
        {
          HB.currentRule = rule;
          HB.cli = rule.contact_list_id;
          // Check to see if the user is eligible for any contentItems
          var eligiblecontentItems = [];
          for(var j=0;j<rule.contentItems.length;j++)
          {
            var content = rule.contentItems[j];
            content.rule = rule;
            if ( !content.target ) {
              eligiblecontentItems.push(content); // If there is no target it is eligible for everyone
            }
            else
            {
              // Check to see if the segment matches if this is a targeted content
              var parts = content.target.split(":");
              var key = parts[0];
              var value = parts.slice(1,parts.length).join(":");
              if ( (typeof HB_ALLOW_ALL !== "undefined" && HB_ALLOW_ALL) || (HB.getUserData(key) || "").toLowerCase() == value.toLowerCase())
                eligiblecontentItems.push(content);
            }
          }
          // See if we have just one eligible content in which case render it
          if ( eligiblecontentItems.length == 1 )
          {
            HB.render(eligiblecontentItems[0]);
            return true;
          }
          else if ( eligiblecontentItems.length > 1 )
          {
            // We need to ask the server which content is the best. 
            HB.pickBestContent(eligiblecontentItems);
            return true;
          }
          else
          {
            // No match
            HB.currentRule = null;
            HB.cli = null;
          }
        }
      }
    }
  },

  // This takes an array of contentItems and sends them to the backend server
  // which will then determine which content to show. However, if we have
  // already shown a user one of these contentItems before we just show them the
  // same content again for consistency and to save a server trip.
  pickBestContent: function(contentItems)
  {
  },

  // This just sets the default segments/tracking data for the user
  // (such as when the suer visited, referrer, etc)
  setDefaultSegments: function()
  {
    var nowDate = new Date();
    var now = Math.round(nowDate.getTime()/1000);
    var day = 24*60*60;

    // Track first visit and most recent visit and time since
    // last visit
    if (!HB.getUserData("fv"))
        HB.setUserData("fv", now);
    // Get the previous visit
    var previousVisit = HB.getUserData("lv");

    // Set the time since the last visit as the number
    // of days
    if ( previousVisit )
      HB.setUserData("ls", Math.round((now-previousVisit)/day));
    HB.setUserData("lv", now);

    // Set the life of the visitor in number of days
    HB.setUserData("lf", Math.round((now-HB.getUserData("fv"))/day));

    // Track number of user visits
    HB.setUserData("nv", (HB.getUserData("nv") || 0)+1);

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
        if ( !HB.getUserData("or" ))
          HB.setUserData("or", referrer);
        // Set the full referrer
        HB.setUserData("rf", referrer);
        // Set the referrer domain
        HB.setUserData("rd", referrerDomain);

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
            HB.setUserData("st", search);
          // Check for UTM variables and set them if present
          HB.setUserData('ad_so', params['utm_source'], true);
          HB.setUserData('ad_ca', params['utm_campaign'], true);
          HB.setUserData('ad_me', params['utm_medium'], true);
          HB.setUserData('ad_co', params['utm_content'], true);
          HB.setUserData('ad_te', params['utm_term'], true);
        }
      }
    }
    // Set the page URL
    HB.setUserData("pu", (document.location+"").split("#")[0]);
    // Set the date
    HB.setUserData("dt", nowDate.getUTCFullYear()+"-"+(nowDate.getUTCMonth()+1)+"-"+nowDate.getUTCDate());
    // Set the timestamp - this can be used for filtering
    HB.setUserData("ts", now);

    // Detect the device
    var ua = navigator.userAgent;
    if (ua.match(/(mobi|phone|ipod|blackberry|docomo)/i))
      HB.setUserData("dv", "mobile");
    else if (ua.match(/(ipad|kindle|android)/i))
      HB.setUserData("dv", "tablet");
    else
      HB.setUserData("dv", "computer");
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
  // Passing no argument leads to "Detect user timezone" mode, as does "auto".
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
