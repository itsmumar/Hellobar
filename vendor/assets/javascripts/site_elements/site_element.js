HB.SiteElement = HB.createClass({
  initialize: function (props) {
    for (var key in props) {
      this[key] = props[key];
    }
  },


  setupIFrame: function (iframe) {
    if (this.animated)
      HB.addClass(iframe, "hb-animated");

    if (this.theme.id)
      HB.addClass(iframe, this.theme.id);

    // Any view_condition including string 'intent' will run the intent event listeners
    if (this.view_condition.indexOf('intent') !== -1) {
      HB.initializeIntentListeners();
    }

    // Starts setIntervals that check display setting conditions
    this.checkForDisplaySetting();
  },

  imagePlacementClass: function () {
    if (!!this.image_url) {
      return 'image-' + this.image_placement;
    } else {
      return '';
    }
  },

  imageFor: function (location) {
    locationIndex = location.indexOf(this.image_placement);
    if (!this.image_url || locationIndex === undefined || locationIndex === -1)
      return '';
    else if (this.image_placement == 'background')
      return '<div class="hb-image-wrapper ' + this.image_placement + '" style="background-image:url(' + this.image_url + ');></div>';
    else
      return '<div class="hb-image-wrapper ' + this.image_placement
        + '"><div class="hb-image-holder hb-editable-block hb-editable-block-image"><img class="uploaded-image" src="'
        + this.image_url + '" /></div></div>';
  },

  blockContent: function (blockId) {
    var blocks = this.blocks || [];
    var foundBlock = null;
    for (var i = 0; i < blocks.length; i++) {
      if (blocks[i].id === blockId) {
        foundBlock = blocks[i];
      }
    }
    return (foundBlock && foundBlock.content) ? foundBlock.content : {};
  },

  attach: function () {
    var that = this;
    if (HB.isIEXOrLess(9)) {
      this.animated = false;
    }

    function generateHtml() {

      var template = '';
      if (that.theme && that.theme.type === 'template') {
        var templateName = that.type.toLowerCase() + '_' + that.theme.id.replace(/\-/g, '_');
        template = HB.getTemplateByName(templateName);
      } else {
        template = HB.getTemplate(that);
      }
      return HB.renderTemplate(template, that);
    }

    var html = generateHtml();
    if (this.type === 'Custom') {
      var customJs = this.custom_js || '';
      html = html + '<script>var hbElement=window.parent.HB.findSiteElementOnPageById(' + this.id + '); ' + customJs + '<\/script>'
    }
    // Once the dom is ready we inject the html returned from renderTemplate
    HB.domReady(function () {

      // Set an arbitrary timeout to prevent some rendering
      // conflicts with certain sites
      setTimeout(function () {
        this.injectSiteElementHTML(html);
        this.setIosKeyboardHandlers();
        this.setPullDown();

        // Monitor zoom scale events
        this.hideOnZoom();

        // Set wiggle listeners
        if (this.wiggle_button.length > 0)
          HB.wiggleEventListeners(this.w);

        this.useGoogleFont();
        if (HB.CAP.preview) {
          this.useFroala();
        }
      }.bind(this), 1);
    }.bind(this));
  },

  // Injects the specified HTML for the given siteElement into the page
  injectSiteElementHTML: function (html) {
    // Remove the containing iframe element if it exists
    if (this.w && this.w.parentNode)
      this.w.parentNode.removeChild(this.w);

    // Remove pull-arrow if it exists
    HB.pd = document.getElementById('pull-down');
    if (HB.pd)
      HB.pd.parentNode.removeChild(HB.pd);

    // Create the iframe container
    this.w = document.createElement('iframe');
    this.w.src = 'about:blank';
    this.w.id = HB_PS + '-container';
    this.w.className = 'HB-' + this.type;
    this.w.name = HB_PS + '-container-' + this.pageIndex;
    HB.hideElement(this.w); // Start all site elements as hidden

    this.setupIFrame(this.w);

    // Check if we have any external CSS to add
    if (HB.extCSS) {
      // If we have already added it, remove it and re-add it
      if (HB.extCSSStyle) {
        HB.extCSSStyle.parentNode.removeChild(HB.extCSSStyle);
      }
      // Create the CSS style tag
      HB.extCSSStyle = document.createElement('STYLE');
      HB.extCSSStyle.type = 'text/css';
      if (HB.extCSSStyle.styleSheet) {
        HB.extCSSStyle.styleSheet.cssText = HB.extCSS;
      }
      else {
        HB.extCSSStyle.appendChild(document.createTextNode(HB.extCSS));
      }
      var head = document.getElementsByTagName('HEAD')[0];
      head.appendChild(HB.extCSSStyle);
    }

    // Inject the container into the DOM
    HB.injectAtTop(this.w);
    // Render the siteElement in the container.
    var d = this.w.contentWindow.document;
    d.open();
    d.write('<html><head>' + (HB.css || '') + '</head><body>' + html + '</body></html>');
    d.close();
    d.body.className = this.type;

    if (this.theme.id) {
      HB.addClass(d.body, this.theme.id);
    }

    if (HB.CAP.preview) {
      HB.addClass(d.body, 'preview-mode');
    }

    // Add IE Specific class overrides
    if (HB.isIEXOrLess(9))
      HB.addClass(d.body, 'hb-old-ie');

    if (HB.isIE11())
      HB.addClass(d.body, 'hb-paused-animations-ie');

    // As the vistor readjust the window size we need to adjust the size of the containing
    // iframe. We do this by checking the the size of the inner div. If the the width
    // of the window is less than or equal to 640 pixels we set the flag isMobileWidth to true.
    // Note: we are not actually detecting a mobile device - just the width of the window.
    // If isMobileWidth is true we add an additional "mobile" CSS class which is used to
    // adjust the style of the siteElement.
    // To accomplish all of this we set up an interval to monitor the size of everything:
    this.isMobileWidth = false;
    var mobileDeviceInterval = setInterval(this.checkForMobileDevice.bind(this), 50); // Check screen size every N ms
  },

  checkForMobileDevice: function () {
    // Get the frame
    var frame = window.frames[HB_PS + "-container-" + this.pageIndex];
    if (!frame)
      return;

    // Get the relevant elements that might need checking/adjusting
    var containerDocument = frame.document;

    var thisElement = this.getSiteElementDomNode();

    // Monitor siteElement height to update HTML/CSS
    if (thisElement) {
      if (thisElement.clientHeight) {

        // Update the CSS class based on the width
        var wasMobile = this.isMobileWidth;
        var containerWidth = HB.previewMode === 'mobile' ? HB.mobilePreviewWidth : document.body.clientWidth;

        if (this.type == "Modal" && containerDocument && !!containerDocument.getElementById("hellobar-modal-background"))
          this.isMobileWidth = (containerDocument.getElementById("hellobar-modal-background").clientWidth <= 640 );
        else if (this.type == "Slider")
          this.isMobileWidth = thisElement.clientWidth <= 270 || containerWidth <= 375 || containerWidth < thisElement.clientWidth;
        else
          this.isMobileWidth = (thisElement.clientWidth <= 640 );


        if (wasMobile != this.isMobileWidth) {
          if (this.isMobileWidth) {
            this.isMobile = true;
            HB.addClass(thisElement, "mobile");
          } else {
            this.isMobile = false;
            HB.removeClass(thisElement, "mobile");
          }
        }

        // Adjust the container size
        this.setContainerSize(this.w, thisElement, this.type, this.isMobile);

        // Bar specific adjustments
        if (this.type == "Bar") {

          // Adjust the pusher
          if (HB.p) {
            // handle case where display-condition check has hidden this.w
            if (this.w.style.display === "none") {
              return;
            }

            var borderPush = HB.t((this.show_border) ? 3 : 0)
            HB.p.style.height = (thisElement.clientHeight + borderPush) + "px";
          }

          // Add multiline class
          var barBounds = (this.w.className.indexOf('regular') > -1 ? 32 : 52 );

          if (thisElement.clientHeight > barBounds) {
            HB.addClass(thisElement, "multiline");
          } else {
            HB.removeClass(thisElement, "multiline");
          }
        }
      }
    }
  },


  setContainerSize: function (container, element, type, isMobile) {
    if (container == null)
      return;
    if (type == 'Bar') {
      container.style.maxHeight = (element.clientHeight + (HB.CAP.preview ? 350 : 8)) + 'px';
      HB.CAP.preview && (container.style.height = (element.clientHeight + 350) + 'px');
    } else if (type == 'Slider') {
      var containerWidth = HB.previewMode === 'mobile' ? HB.mobilePreviewWidth : window.innerWidth;
      var newWidth = Math.min(HB.maxSliderSize + 24, containerWidth - 24);
      container.style.width = (newWidth) + 'px';

      // Increase <iframe> bounds for non-mobile preview (so that Froala editor
      // controls are visible/usable)
      container.style.height = (element.clientHeight + (HB.CAP.preview && HB.previewMode !== 'mobile' ? 450 : 124)) + 'px';
    }
  },

  getSiteElementDomNode: function () {
    var el;
    if (this.w && this.w.contentDocument) {
      for (var key in HB.id_type_map) {
        el = this.w.contentDocument.getElementById(key);
        if (el) {
          return el;
        }
      }
      el = this.w.contentDocument.getElementById('hellobar-template');
      if (el) {
        return el;
      }
    }
    return null;
  },


  // Reads the site element's view_condition setting and calls hide/show per selected behavior
  // if viewCondition is missing or badly formed, siteElement displays immediately by default

  checkForDisplaySetting: function () {
    var viewCondition = this.view_condition;
    var originalDisplay = this.w.style.display;

    if (document.getElementById('hellobar-preview-container') !== null)
      viewCondition = 'preview';

    var show = function () {
      clearInterval(this.displayCheckInterval);
      HB.showElement(this.w);

      // Track the view
      if (!this.dontRecordView) {
        HB.viewed(this);
      }

      // Next line is a Safari hack.  Couldn't find out why but sometimes safari
      // wouldn't display the contents of the iframe, but toggling the display style fixes this
      // UPDATE:  1/25/16 - DP
      // runnig this hack on all browsers since we had issues with desktop Safari and Chrome
      var siteElementNode = this.getSiteElementDomNode();
      if (siteElementNode) {
        siteElementNode.style.display = 'none';
        setTimeout(function () {
          siteElementNode.style.display = '';
        }, 10);
      }

      if (this.w.className.indexOf("hb-animated") > -1) {
        HB.animateIn(this.w)
      }
    }.bind(this);

    var showMinimizedBar = function () {
      HB.hideElement(this.w);
      HB.animateIn(this.pullDown);
    }.bind(this);

    if (viewCondition === 'wait-5') {
      setTimeout(show, 5000);
    }
    else if (viewCondition === 'wait-10') {
      setTimeout(show, 10000);
    }
    else if (viewCondition === 'wait-30') {
      setTimeout(show, 30000);
    }
    else if (viewCondition === 'wait-60') {
      setTimeout(show, 60000);
    }
    else if (viewCondition === 'scroll-some') {
      // scroll-some is defined here as "visitor scrolls 300 pixels"
      this.displayCheckInterval = setInterval(function () {
        HB.scrollTargetCheck(300, show)
      }, 500);
    }
    else if (viewCondition === 'scroll-middle') {
      this.displayCheckInterval = setInterval(function () {
        HB.scrollTargetCheck("middle", show)
      }, 500);
    }
    else if (viewCondition === 'scroll-to-bottom') {
      this.displayCheckInterval = setInterval(function () {
        HB.scrollTargetCheck("bottom", show)
      }, 500);
    }
    else if (viewCondition === 'exit-intent') {
      this.displayCheckInterval = setInterval(function () {
        HB.intentCheck("exit", show)
      }, 100);
    }
    else if (viewCondition == 'stay-hidden') {
      setTimeout(showMinimizedBar, 500);
    }
    else {
      // No view condition so show immediately (very small delay for animated elements)
      if (this.w.className.indexOf("hb-animated") > -1)
        setTimeout(show, 500);
      else
        show();
    }
  },

  hideOnZoom: function () {
    // Doesn't work IE 9 and earlier
    if (!window.addEventListener || !window.outerWidth || !window.innerWidth) return;

    var original = this.w.style.position;
    var action = function (e) {
      var ratio = (window.outerWidth - 8) / window.innerWidth;

      if (e.scale) {
        // iPhone
        this.w.style.position = (e.scale <= 1.03) ? original : 'absolute';
      } else if (typeof window.orientation !== 'undefined') { // Not mobile
        // Android
        if (window.outerWidth <= 480 && ratio <= 1.3) {
          return this.w.style.position = original;
        }
        this.w.style.position = (ratio <= 0.6) ? original : 'absolute';
      } else {
        // Desktop
        if (this.type == "Slider") {
          // dont change the position to allow scrolling
        } else {
          this.w.style.position = (ratio <= 1.3) ? original : 'absolute';
        }
      }
    }.bind(this);

    // iPhone
    window.addEventListener('gesturechange', action);

    // Android
    window.addEventListener('scroll', action);
  },

  remove: function () {
    if (this.w != null && this.w.parentNode != null) {
      this.w.parentNode.removeChild(this.w);
      // Note: this should really clean up event listeners
      // and timers too
      return true;
    }
    return false;
  },


  close: function () {
    if (HB.preventElementClosing) {
      return;
    }
    HB.animateOut(this.w, this.onClosed.bind(this));
  },

  onClosed: function () {
    // Remove the element
    if (this.remove()) {
      // Sets the dismissed state for the next 15 minutes
      HB.sc("HBDismissed-" + this.id, true, new Date((new Date().getTime() + 1000 * 60 * 15)), "path=/");

      HB.setVisibilityControlCookie('dismiss', this);

      // Track specific elements longer, for takeovers/modals
      var expiration, cookie_name, cookie_str, dismissed_elements;
      if (this.type == "Takeover" || this.type == "Modal") {
        expiration = 86400000 * 365 * 5; // 5 years
        cookie_name = "HBDismissedModals";
      } else {
        // Track specific elements 24 hours, for bars/sliders
        expiration = 86400000; // 24 hours
        cookie_name = "HBDismissedBars";
      }
      cookie_str = HB.gc(cookie_name) || "[]";
      dismissed_elements = JSON.parse(cookie_str) || [];
      if (dismissed_elements.indexOf(this.id) == -1) {
        dismissed_elements.push(this.id);
      }
      if (dismissed_elements) {
        HB.sc(
          cookie_name,
          JSON.stringify(dismissed_elements),
          new Date((new Date().getTime() + expiration)),
          "path=/"
        );
      }
    }

    HB.trigger("elementDismissed"); // Old-style trigger
    HB.trigger("closed", this); // New trigger
  },

  // Create the pulldown arrow element for when a bar is hidden
  // The pulldown arrow is only created when a site element is closable
  setPullDown: function () {
    // Create the pull down elements
    if (this.closable) {
      var pullDown = document.createElement("div");
      pullDown.className = "hb-" + this.size + " hellobar " + "hb-" + this.placement;
      pullDown.id = "pull-down";

      pullDown.style.backgroundColor = "#" + this.background_color;
      var pdLink = document.createElement("div");
      pdLink.className = "hellobar-arrow";
      pdLink.onclick = function () {
        HB.animateIn(this.w);
        HB.animateOut(this.pullDown);

        // if the pusher exists, unhide it since it should be hidden at this point
        if (HB.p != null)
          HB.showElement(HB.p, '');
      }.bind(this);

      pullDown.appendChild(pdLink);
      HB.injectAtTop(pullDown);
      this.pullDown = pullDown;
    }
  },

  setIosKeyboardHandlers: function () {
    if (!HB.isMobileSafari()) {
      return;
    }

    var inputs = this.w.contentDocument.getElementsByTagName("input");
    for (var i = 0; i < inputs.length; i++) {
      inputs[i].addEventListener("focus", this.iosKeyboardShow.bind(this));
      inputs[i].addEventListener("blur", this.iosKeyboardHide.bind(this));
    }
  },

  iosKeyboardShow: function (e) {
    e.preventDefault();
    var element = this;

    if (this.type == "Bar") {
      HB.iosFocusInterval = setTimeout(function () {
        window.scrollTo(0, element.w.offsetTop);
      }, 500);
    }
    else if (this.type == "Slider") {
      this.w.style.position = "absolute";
      HB.iosFocusInterval = setInterval(function () {
        element.w.style.left = window.pageXOffset + "px";
        element.w.style.top = window.pageYOffset + "px";
      }, 200);
    }
    else if
    (
      this.type == "Takeover" ||
      this.type == "Modal" ||
      this.type == "Custom"
    ) {
      this.updateStyleFor(false);
    }
  },

  iosKeyboardHide: function (e) {
    e.preventDefault();

    if (HB.iosFocusInterval != null) {
      clearInterval(HB.iosFocusInterval);
      HB.iosFocusInterval = null;
    }

    if (
      this.type == "Takeover" ||
      this.type == "Modal" ||
      this.type == "Slider" ||
      this.type == "Custom"
    ) {
      this.updateStyleFor(true);
    }
  },

  updateStyleFor: function (reset) {
    var element = this;
    var contentDocument = element.w.contentDocument;
    var hbModal = contentDocument.getElementById('hellobar-modal') || contentDocument.getElementById('hellobar-takeover')|| contentDocument.getElementById('hellobar-custom');

    if (reset) {
      this.w.style.position = "";
      this.w.style.height = "";
      this.w.style.maxHeight = "";
      this.w.style.width = "";
      this.w.style.left = "";
      this.w.style.top = "";
      this.w.style["-webkit-transform"] = "";

      hbModal.style.position = "";
      hbModal.style.overflowY = "";
      hbModal.style.maxHeight = "";
      hbModal.style.height = "";
      hbModal.style.top = "";
      hbModal.style.left = "";
      hbModal.style.transform = "";
      hbModal.style.width = "";
    } else {
      var modalMaxHeight = hbModal.getElementsByClassName('hb-text-wrapper')[0].clientHeight;

      element.w.style.position = "absolute";
      HB.iosFocusInterval = setInterval(function () {
        element.w.style.height = window.innerHeight + "px";
        element.w.style.maxHeight = window.innerHeight + "px";
        element.w.style.width = window.innerWidth + "px";
        element.w.style.left = "0";
        element.w.style.top = "0";
        element.w.style["-webkit-transform"] = "scale(0.9)";

        if (hbModal != undefined && hbModal != null) {
          hbModal.style.position = "absolute";
          hbModal.style.overflowY = "scroll";
          hbModal.style.maxHeight = "100%";
          hbModal.style.height = "100%";
          hbModal.style.top = "0";
          hbModal.style.left = "0";
          hbModal.style.transform = "none";
          hbModal.style.width = "100%";
        }
      }, 0);

      hbModal.scrollIntoView();
      contentDocument.getElementsByClassName('hb-content-wrapper')[0].scrollIntoView();
      window.scrollTo(0, window.innerHeight / 2);
    }
    return false;
  },

  // Necessary convenience method for saying this
  // SiteElement has converted (used in templates)
  converted: function () {
    HB.converted(this);
  },

  useGoogleFont: function () {
    if (!this.google_font) return;
    var head = this.w.contentWindow.document.getElementsByTagName('head')[0];

    var link = this.w.contentWindow.document.createElement("LINK");
    link.href = 'https://fonts.googleapis.com/css?family=' + this.google_font;
    link.rel = 'stylesheet';
    link.type = 'text/css';

    head.appendChild(link);

    // if is mobile safari, prevent from zooming
    if (HB.isMobileSafari()) {
      var meta = this.w.contentWindow.document.createElement("META");
      meta.name = "viewport";
      meta.content = "width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no";
      head.appendChild(meta);
    }
  },

  addCss: function (href) {
    var head = this.w.contentWindow.document.getElementsByTagName('head')[0];
    var link = this.w.contentWindow.document.createElement("LINK");
    link.href = href;
    link.rel = 'stylesheet';
    link.type = 'text/css';
    head.appendChild(link);
  },

  addJs: function (href) {
    var head = this.w.contentWindow.document.getElementsByTagName('head')[0];
    var script = this.w.contentWindow.document.createElement("SCRIPT");
    script.src = href;
    script.type = 'text/javascript';
    head.appendChild(script);
  },

  useFroala: function () {
    this.addCss('//cdnjs.cloudflare.com/ajax/libs/font-awesome/4.4.0/css/font-awesome.min.css');
    this.addCss('//cdnjs.cloudflare.com/ajax/libs/froala-editor/2.3.5/css/froala_editor.min.css');
    //removeing this and cherry picking styles in common.css
    //this.addCss('//cdnjs.cloudflare.com/ajax/libs/froala-editor/2.3.5/css/froala_style.css');
    this.addCss('//cdnjs.cloudflare.com/ajax/libs/froala-editor/2.3.5/css/plugins/colors.min.css');
    this.addCss('//cdnjs.cloudflare.com/ajax/libs/froala-editor/2.3.5/css/plugins/emoticons.css');
    this.addCss('//cdnjs.cloudflare.com/ajax/libs/froala-editor/2.3.5/css/plugins/image.min.css');
  },

  brightnessClass: function () {
    if (this.getBrightness(this.background_color) < 0.25) //an empirical value most suitable for all backgrounds
      return "dark";
    else
      return "light";
  },

  //get brightness of site element by its background color using specific formula from "preview-controller.coffee" file
  getBrightness: function (x) {
    x = x || "";
    var rgb = [ //transform hex string to array
      x[0] + x[1],
      x[2] + x[3],
      x[4] + x[5]
    ];


    rgb.forEach(function (hex, i) {
      var dec = parseInt(hex, 16); //hex to decimal
      var val = dec / 255; //decimal to fraction

      rgb[i] = val < 0.03928 ? val / 12.92 : Math.pow((val + 0.055) / 1.055, 2.4);
    });

    return (0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]);
  }
});
