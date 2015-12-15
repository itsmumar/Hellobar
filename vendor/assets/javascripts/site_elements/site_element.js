HB.SiteElement = HB.createClass({
  initialize: function(props)
  {
    for (var key in props) {
      this[key] = props[key];
    }
  },

  setupIFrame: function(iframe) {
    if(this.animated) {
      HB.addClass(iframe, "hb-animated");
    }

    // Any view_condition including string 'intent' will run the intent event listeners
    if (this.view_condition.indexOf('intent') !== -1) {
      HB.initializeIntentListeners();
    };

    // Starts setIntervals that check display setting conditions
    this.checkForDisplaySetting();
  },

  prerender: function(){
    HB.sanitize(this);
    if(HB.isIEXOrLess(9))
      this.animated = false;
  },

  imagePlacementClass: function() {
    if(!!this.image_url) {
      return 'image-' + this.image_placement;
    } else {
      return '';
    }
  },

  imageFor: function(location) {
    if (!this.image_url || location.indexOf(this.image_placement) == -1)
      return "";
    else
      return "<div class='hb-image-wrapper " + this.image_placement + "'><img class='uploaded-image' src=" + this.image_url + " /></div>";
  },

  render: function() {
    // Replace all the templated variables
    var html = HB.renderTemplate(HB.getTemplate(this)+"", this);
    // Once the dom is ready we inject the html returned from renderTemplate
    HB.domReady(function(){
      // Set an arbitrary timeout to prevent some rendering
      // conflicts with certain sites
      setTimeout(function(){
        this.injectSiteElementHTML(html);
        this.setIosKeyboardHandlers();
        this.setPullDown()
          // Track the view
          HB.viewed();
        // Monitor zoom scale events
        this.hideOnZoom();

        // Set wiggle listeners
        if(this.wiggle_button.length > 0)
          HB.wiggleEventListeners(HB.w);
      }.bind(this), 1);
    }.bind(this));
  },


  // Injects the specified HTML for the given siteElement into the page
  injectSiteElementHTML: function(html)
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
    HB.w.id = HB_PS + "-container";
    HB.w.className = "HB-" + this.type;
    HB.w.name = HB_PS + "-container";
    HB.hideElement(HB.w); // Start all site elements as hidden

    this.setupIFrame(HB.w)

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
    d.body.className = this.type;
    if(HB.isIEXOrLess(9))
      HB.addClass(d.body, "hb-old-ie");

    if(HB.isIE11())
      HB.addClass(d.body, "hb-paused-animations-ie");

    // As the vistor readjust the window size we need to adjust the size of the containing
    // iframe. We do this by checking the the size of the inner div. If the the width
    // of the window is less than or equal to 640 pixels we set the flag isMobileWidth to true.
    // Note: we are not actually detecting a mobile device - just the width of the window.
    // If isMobileWidth is true we add an additional "mobile" CSS class which is used to
    // adjust the style of the siteElement.
    // To accomplish all of this we set up an interval to monitor the size of everything:
    HB.isMobileWidth = false;
    var mobileDeviceInterval = setInterval(this.checkForMobileDevice.bind(this), 50); // Check screen size every N ms
  },

  checkForMobileDevice: function(){
    // Get the frame
    var frame = window.frames[HB_PS + "-container"];
    if ( !frame )
      return;

    // Get the relevant elements that might need checking/adjusting
    var containerDocument = frame.document;
    HB.e = {
      container: HB.$("#" + HB_PS + "-container"),
      pusher: HB.$("#hellobar-pusher")
    };

    var foundElement = this.getSiteElementDomNode();
    if ( foundElement ) {
      HB.e.siteElement = foundElement;
      HB.e.siteElementType = HB.id_type_map[foundElement.id]
    } else {
      HB.e.siteElement = null;
      HB.e.siteElementType = null;
    }

    // Monitor siteElement height to update HTML/CSS
    if ( HB.e.siteElement ) {
      if ( HB.e.siteElement.clientHeight ) {

        // Update the CSS class based on the width
        var wasMobile = HB.isMobileWidth;

        if ( HB.e.siteElementType == "modal" && containerDocument )
          HB.isMobileWidth = (containerDocument.getElementById("hellobar-modal-background").clientWidth <= 640 );
        else if ( HB.e.siteElementType == "slider" )
          HB.isMobileWidth = HB.e.siteElement.clientWidth <= 270 || document.body.clientWidth <= 375 || document.body.clientWidth < HB.e.siteElement.clientWidth;
        else
          HB.isMobileWidth = (HB.e.siteElement.clientWidth <= 640 );

        if ( wasMobile != HB.isMobileWidth ) {
          if ( HB.isMobileWidth ) {
            HB.isMobile = true;
            HB.addClass(HB.e.siteElement, "mobile");
          } else {
            HB.isMobile = false;
            HB.removeClass(HB.e.siteElement, "mobile");
          }
        }

        // Adjust the container size
        this.setContainerSize(HB.e.container, HB.e.siteElement, HB.e.siteElementType, HB.isMobile);

        // Bar specific adjustments
        if ( HB.e.siteElementType == "bar" ) {

          // Adjust the pusher
          if ( HB.e.pusher ) {
            // handle case where display-condition check has hidden HB.w
            if (HB.w.style.display === "none") {
              return;
            };

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
  },


  setContainerSize:  function(container, element, type, isMobile)
  {
    if (HB.e.container == null)
      return;
    if ( type == 'bar' ) {
      HB.e.container.style.maxHeight = (element.clientHeight + 8) + "px";
    } else if ( type == 'slider' ) {
      var newWidth = Math.min(HB.maxSliderSize + 24, window.innerWidth - 24);
      HB.e.container.style.width = (newWidth) + "px";
      HB.e.container.style.height = (element.clientHeight + 24) + "px";
    }
  },

  getSiteElementDomNode:  function() {
    if(HB.w && HB.w.contentDocument) {
      for(var key in HB.id_type_map) {
        var el = HB.w.contentDocument.getElementById(key);
        if(el != undefined)
          return el;
      }
    }
    return null;
  },


  // Reads the site element's view_condition setting and calls hide/show per selected behavior
  // if viewCondition is missing or badly formed, siteElement displays immediately by default

  checkForDisplaySetting:  function()
  {
    var viewCondition = this.view_condition;
    var originalDisplay = HB.w.style.display;

    if (document.getElementById('hellobar-preview-container') !== null)
      viewCondition = 'preview';

    var show = function() {
      HB.showElement(HB.w);

      // Next line is a Safari hack.  Couldn't find out why but sometimes safari
      // wouldn't display the contents of the iframe, but toggling the display style fixes this
      if(HB.isMobileSafari()) {
        var siteElementNode = this.getSiteElementDomNode();
        if(siteElementNode) {
          siteElementNode.style.display = 'none';
          setTimeout(function() {
            siteElementNode.style.display = '';
          }, 10);
        }
      }

      if (HB.w.className.indexOf("hb-animated") > -1) { HB.animateIn(HB.w) };
    }

    if (viewCondition === 'wait-5')
    {
      setTimeout(show, 5000);
    }
    else if (viewCondition === 'wait-10')
    {
      setTimeout(show, 10000);
    }
    else if (viewCondition === 'wait-60')
    {
      setTimeout(show, 60000);
    }
    else if (viewCondition === 'scroll-some')
    {
      // scroll-some is defined here as "visitor scrolls 300 pixels"
      HB.scrollInterval = setInterval(function(){HB.scrollTargetCheck(300, show)}, 500);
    }
    else if (viewCondition === 'scroll-middle')
    {
      HB.scrollInterval = setInterval(function(){HB.scrollTargetCheck("middle", show)}, 500);
    }
    else if (viewCondition === 'scroll-to-bottom')
    {
      HB.scrollInterval = setInterval(function(){HB.scrollTargetCheck("bottom", show)}, 500);
    }
    else if (viewCondition === 'exit-intent')
    {
      HB.intentInterval = setInterval(function(){HB.intentCheck("exit", show)}, 100);
    }
    else {
      // No view condition so show immediately (very small delay for animated elements)
      if (HB.w.className.indexOf("hb-animated") > -1)
        setTimeout(show, 500);
      else
        show();
    }
  },

  hideOnZoom:  function() {
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

  closeIframe:  function() {
    if(HB.w != null && HB.w.parentNode != null) {
      HB.w.parentNode.removeChild(HB.w);
      // Sets the dismissed state for the next 15 minutes
      HB.sc("HBDismissed", true, new Date((new Date().getTime() + 1000 * 60 * 15)), "path=/");
    }

    HB.trigger("elementDismissed");
  },

  // Create the pulldown arrow element for when a bar is hidden
  // The pulldown arrow is only created when a site element is closable
  setPullDown: function() {
    // Create the pull down elements
    if(this.closable) {
      var pullDown = document.createElement("div");
      pullDown.className = "hb-" + this.size + " hellobar " + "hb-" + this.placement;
      pullDown.id = "pull-down";

      pullDown.style.backgroundColor = "#" + this.background_color;
      var pdLink = document.createElement("div");
      pdLink.className = "hellobar-arrow";
      pdLink.onclick = function() {
        HB.animateIn(HB.w);
        HB.animateOut(document.getElementById("pull-down"));

        // if the pusher exists, unhide it since it should be hidden at this point
        if (HB.e.pusher != null)
          HB.showElement(HB.e.pusher, '');
      };

      pullDown.appendChild(pdLink);
      HB.injectAtTop(pullDown);
    }
  },

  setIosKeyboardHandlers: function() {
    if(!HB.isMobileSafari()) {
      return;
    }

    var inputs = HB.w.contentDocument.getElementsByTagName("input");
    for (var i = 0; i < inputs.length; i++) {
      inputs[i].addEventListener("focus", this.iosKeyboardShow.bind(this) );
      inputs[i].addEventListener("blur", this.iosKeyboardHide.bind(this) );
    }
  },

  iosKeyboardShow: function() {
    if(HB.e.siteElementType == "slider" || HB.e.siteElementType == "bar") {
      HB.iosFocusInterval = setTimeout(function() { window.scrollTo(0, HB.w.offsetTop); }, 500);
    } else if(HB.e.siteElementType == "takeover" || HB.e.siteElementType == "modal") {
      HB.w.style.position = "absolute";
      HB.iosFocusInterval = setInterval(function() {
        HB.w.style.height = window.innerHeight + "px";
        HB.w.style.width = window.innerWidth + "px";
        HB.w.style.top = window.pageYOffset + "px";
        HB.w.style.left = window.pageXOffset + "px";
      }, 200);
    }
  },

  iosKeyboardHide:  function() {
    if(HB.iosFocusInterval != null) {
      clearInterval(HB.iosFocusInterval);
      HB.iosFocusInterval = null;
    }

    if(HB.e.siteElementType == "takeover" || HB.e.siteElementType == "modal") {
      HB.w.style.position = "";
      HB.w.style.height = "";
      HB.w.style.width = "";
      HB.w.style.top = "";
      HB.w.style.left = "";
    }
  }

});
