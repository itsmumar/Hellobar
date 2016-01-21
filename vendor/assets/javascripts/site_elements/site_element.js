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

  attach: function()
  {
    if(HB.isIEXOrLess(9))
      this.animated = false;
    // Replace all the templated variables
    var html = HB.renderTemplate(HB.getTemplate(this)+"", this);
    // Once the dom is ready we inject the html returned from renderTemplate
    HB.domReady(function(){
      // Set an arbitrary timeout to prevent some rendering
      // conflicts with certain sites
      setTimeout(function(){
        this.injectSiteElementHTML(html);
        this.setIosKeyboardHandlers();
        this.setPullDown();
        // Track the view
        HB.viewed(this);
        // Monitor zoom scale events
        this.hideOnZoom();

        // Set wiggle listeners
        if(this.wiggle_button.length > 0)
          HB.wiggleEventListeners(this.w);
      }.bind(this), 1);
    }.bind(this));
  },

  // Injects the specified HTML for the given siteElement into the page
  injectSiteElementHTML: function(html)
  {
    // Remove the containing iframe element if it exists
    if ( this.w &&  this.w.parentNode)
      this.w.parentNode.removeChild(this.w);

    // Remove pull-arrow if it exists
    HB.pd = document.getElementById("pull-down");
    if ( HB.pd )
      HB.pd.parentNode.removeChild(HB.pd);

    // Create the iframe container
    this.w = document.createElement("iframe");
    this.w.src = "about:blank";
    this.w.id = HB_PS + "-container";
    this.w.className = "HB-" + this.type;
    this.w.name = HB_PS + "-container-"+this.pageIndex;
    HB.hideElement(this.w); // Start all site elements as hidden

    this.setupIFrame(this.w)

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
    HB.injectAtTop(this.w);
    // Render the siteElement in the container.
    var d = this.w.contentWindow.document;
    d.open();
    d.write("<html><head>" + (HB.css || "") + "</head><body>" + html + "</body></html>");
    d.close();
    d.body.className = this.type;
    if(HB.isIEXOrLess(9))
      HB.addClass(d.body, "hb-old-ie");

    if(HB.isIE11())
      HB.addClass(d.body, "hb-paused-animations-ie");

    if(siteElement.use_question) {
      this.displayQuestion();
    }

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
    var frame = window.frames[HB_PS + "-container-"+this.pageIndex];
    if ( !frame )
      return;

    // Get the relevant elements that might need checking/adjusting
    var containerDocument = frame.document;
    this.e = {
      container: this.w,
      pusher: HB.$("#hellobar-pusher")
    };

    var foundElement = this.getSiteElementDomNode();
    if ( foundElement ) {
      this.e.siteElement = foundElement;
      this.e.siteElementType = HB.id_type_map[foundElement.id]
    } else {
      this.e.siteElement = null;
      this.e.siteElementType = null;
    }

    // Monitor siteElement height to update HTML/CSS
    if ( this.e.siteElement ) {
      if ( this.e.siteElement.clientHeight ) {

        // Update the CSS class based on the width
        var wasMobile = HB.isMobileWidth;

        if ( this.e.siteElementType == "modal" && containerDocument )
          HB.isMobileWidth = (containerDocument.getElementById("hellobar-modal-background").clientWidth <= 640 );
        else if ( this.e.siteElementType == "slider" )
          HB.isMobileWidth = this.e.siteElement.clientWidth <= 270 || document.body.clientWidth <= 375 || document.body.clientWidth < this.e.siteElement.clientWidth;
        else
          HB.isMobileWidth = (this.e.siteElement.clientWidth <= 640 );

        if ( wasMobile != HB.isMobileWidth ) {
          if ( HB.isMobileWidth ) {
            HB.isMobile = true;
            HB.addClass(this.e.siteElement, "mobile");
          } else {
            HB.isMobile = false;
            HB.removeClass(this.e.siteElement, "mobile");
          }
        }

        // Adjust the container size
        this.setContainerSize(this.e.container, this.e.siteElement, this.e.siteElementType, HB.isMobile);

        // Bar specific adjustments
        if ( this.e.siteElementType == "bar" ) {

          // Adjust the pusher
          if ( this.e.pusher ) {
            // handle case where display-condition check has hidden this.w
            if (this.w.style.display === "none") {
              return;
            };

            var borderPush = HB.t((this.show_border) ? 3 : 0)
              this.e.pusher.style.height = (this.e.siteElement.clientHeight + borderPush) + "px";
          }

          // Add multiline class
          var barBounds = (this.w.className.indexOf('regular') > -1 ? 32 : 52 );

          if ( this.e.siteElement.clientHeight > barBounds ) {
            HB.addClass(this.e.siteElement, "multiline");
          } else {
            HB.removeClass(this.e.siteElement, "multiline");
          }
        }
      }
    }
  },


  setContainerSize:  function(container, element, type, isMobile)
  {
    if (this.e.container == null)
      return;
    if ( type == 'bar' ) {
      this.e.container.style.maxHeight = (element.clientHeight + 8) + "px";
    } else if ( type == 'slider' ) {
      var newWidth = Math.min(HB.maxSliderSize + 24, window.innerWidth - 24);
      this.e.container.style.width = (newWidth) + "px";
      this.e.container.style.height = (element.clientHeight + 24) + "px";
    }
  },

  getSiteElementDomNode:  function() {
    if(this.w && this.w.contentDocument) {
      for(var key in HB.id_type_map) {
        var el = this.w.contentDocument.getElementById(key);
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
    var originalDisplay = this.w.style.display;

    if (document.getElementById('hellobar-preview-container') !== null)
      viewCondition = 'preview';

    var show = function() {
      HB.showElement(this.w);

      // Next line is a Safari hack.  Couldn't find out why but sometimes safari
      // wouldn't display the contents of the iframe, but toggling the display style fixes this
      // UPDATE:  1/25/16 - DP
      // runnig this hack on all browsers since we had issues with desktop Safari and Chrome
      var siteElementNode = this.getSiteElementDomNode();
      if(siteElementNode) {
        siteElementNode.style.display = 'none';
        setTimeout(function() {
          siteElementNode.style.display = '';
        }, 10);
      }

      if (this.w.className.indexOf("hb-animated") > -1) { HB.animateIn(this.w) };
    }.bind(this);

    var showMinimizedBar = function() {
      HB.hideElement(this.w);
      HB.animateIn(this.pullDown);
    }.bind(this);

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
    else if (viewCondition == 'stay-hidden')
    {
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

  hideOnZoom:  function() {
    // Doesn't work IE 9 and earlier
    if (!window.addEventListener || !window.outerWidth || !window.innerWidth) return;

    var original = this.w.style.position;
    var action = function(e) {
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
        this.w.style.position = (ratio <= 1.3) ? original : 'absolute';
      }
    }.bind(this);

    // iPhone
    window.addEventListener('gesturechange', action);

    // Android
    window.addEventListener('scroll', action);
  },

  remove: function()
  {
    if(this.w != null && this.w.parentNode != null)
    {
      this.w.parentNode.removeChild(this.w);
      // Note: this should really clean up event listeners
      // and timers too
      return true;
    }
    return false;
  },


  close:  function()
  {
    HB.animateOut(this.w, this.onClosed.bind(this));
  },

  onClosed: function()
  {
    // Remove the element
    if ( this.remove() )
    {
      // Sets the dismissed state for the next 15 minutes
      HB.sc("HBDismissed", true, new Date((new Date().getTime() + 1000 * 60 * 15)), "path=/");

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
        HB.animateIn(this.w);
        HB.animateOut(this.pullDown);

        // if the pusher exists, unhide it since it should be hidden at this point
        if (this.e.pusher != null)
          HB.showElement(this.e.pusher, '');
      }.bind(this);

      pullDown.appendChild(pdLink);
      HB.injectAtTop(pullDown);
      this.pullDown = pullDown;
    }
  },

  setIosKeyboardHandlers: function() {
    if(!HB.isMobileSafari()) {
      return;
    }

    var inputs = this.w.contentDocument.getElementsByTagName("input");
    for (var i = 0; i < inputs.length; i++) {
      inputs[i].addEventListener("focus", this.iosKeyboardShow.bind(this) );
      inputs[i].addEventListener("blur", this.iosKeyboardHide.bind(this) );
    }
  },

  iosKeyboardShow: function() {
    if(this.e.siteElementType == "slider" || this.e.siteElementType == "bar") {
      HB.iosFocusInterval = setTimeout(function() { window.scrollTo(0, this.w.offsetTop); }, 500);
    } else if(this.e.siteElementType == "takeover" || this.e.siteElementType == "modal") {
      this.w.style.position = "absolute";
      HB.iosFocusInterval = setInterval(function() {
        this.w.style.height = window.innerHeight + "px";
        this.w.style.width = window.innerWidth + "px";
        this.w.style.top = window.pageYOffset + "px";
        this.w.style.left = window.pageXOffset + "px";
      }, 200);
    }
  },

  iosKeyboardHide:  function() {
    if(HB.iosFocusInterval != null) {
      clearInterval(HB.iosFocusInterval);
      HB.iosFocusInterval = null;
    }

    if(this.e.siteElementType == "takeover" || this.e.siteElementType == "modal") {
      this.w.style.position = "";
      this.w.style.height = "";
      this.w.style.width = "";
      this.w.style.top = "";
      this.w.style.left = "";
    }
  },

  // Necessary convenience method for saying this
  // SiteElement has converted (used in templates)
  converted: function()
  {
    HB.converted(this);
  },

  originalElements: function() {
    if (this._originalElements == undefined) {
      var d = this.w.contentWindow.document;
      this._originalElements = {
        'headline':      d.querySelector('.hb-headline-text'),
        'cta':           d.querySelector('#hb-traffic-cta'),
        'emailForm':     d.querySelector('.hb-input-wrapper'),
        'emailFormBtn':  d.querySelector('.hb-input-wrapper .hb-cta'),
        'caption':       d.querySelector('.hb-text-wrapper .hb-secondary-text'),
        'social':        d.querySelectorAll('.hb-social-wrapper')
      }
    }
    return this._originalElements;
  },

  extractQuestionElements: function() {
    if (this._questionElements == undefined) {
      var d = this.w.contentWindow.document;
      this._questionElements = {
        'questionText':  d.querySelector('#hb-question'),
        'answers':       d.querySelector('#hb-answers'),
        'responseText1': d.querySelector('#hb-answer1-response span'),
        'responseText2': d.querySelector('#hb-answer2-response span'),
        'response-cta1': d.querySelector('#hb-answer1-response a'),
        'response-cta2': d.querySelector('#hb-answer2-response a'),
        'captionText1':  d.querySelector('#hb-answer1-caption'),
        'captionText2':  d.querySelector('#hb-answer2-caption')
      }
      if (this.subtype.match(/social|announcement/)) {
        this._questionElements['response-cta1'] = null;
        this._questionElements['response-cta2'] = null;
      }
    }
    return this._questionElements;
  },

  hideOriginalElements: function() {
    var original = this.originalElements();
    // hide original elements to show later
    HB.hideElement(original['emailForm']);
    HB.hideElement(original['social']);
  },

  currentHeadline: function() {
    return this.w.contentWindow.document.querySelector('.hb-headline-text');
  },

  currentCaption: function() {
    return this.w.contentWindow.document.querySelector('.hb-text-wrapper .hb-secondary-text');
  },

  rewriteElementText: function(element, elementText) {
    if (element && elementText) {
      element.textContent = elementText.textContent;
    }
  },

  rewriteEmailCTA: function(new_cta){
    var original     = this.originalElements();
    var emailFormBtn = original['emailFormBtn'];
    var answers      = this.extractQuestionElements()['answers'];

    this.rewriteElementText(emailFormBtn, new_cta);
    HB.hideElement(new_cta, "");
    HB.hideElement(answers, "");
  },

  showAnswers: function() {
    var original  = this.originalElements();
    var emailForm = original['emailForm'];
    var cta =       original['cta'];

    var elements  = this.extractQuestionElements();
    var answers = elements['answers'];

    if(emailForm) {
      emailForm.parentNode.appendChild(answers);
    } else {
      if(cta) { HB.hideElement(cta) }
      this.currentHeadline().appendChild(answers);
    }
    HB.showElement(answers, "inline");
  },

  displayQuestion: function() {
    var elements  = this.extractQuestionElements();
    this.hideOriginalElements();
    this.rewriteElementText(this.currentHeadline(), elements['questionText']);
    this.showAnswers();
  },

  displayResponse: function(idx) {
    var elements     = this.extractQuestionElements();
    var answers      = elements['answers'];
    var cta          = elements['response-cta'+idx];
    var other_cta    = elements['response-cta'+(idx == 1 ? 2 : 1)];
    var original = this.originalElements();
    var emailFormBtn = original['emailFormBtn'];

    HB.hideElement(answers);
    HB.hideElement(other_cta);
    if (emailFormBtn) {
      this.rewriteEmailCTA(cta, answers, emailFormBtn);
    } else if (cta && cta.parentNode != this.currentHeadline().parentNode) {
      this.currentHeadline().parentNode.appendChild(cta);
    }
    if (cta) { HB.showElement(cta, ""); }
    HB.showElement(original['emailForm'], "");
    HB.showElement(original['social'], "");
    this.rewriteElementText(this.currentHeadline(), elements['responseText'+idx]);
    this.rewriteElementText(this.currentCaption(), elements['captionText'+idx]);
  }

});
