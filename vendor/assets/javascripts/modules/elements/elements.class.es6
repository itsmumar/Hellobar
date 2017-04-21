hellobar.defineModule('elements.class',
  ['hellobar',
    'base.templating', 'base.dom', 'base.site', 'base.environment', 'base.preview', 'base.coloring', 'base.format', 'base.capabilities', 'base.bus',
    'elements.visibility', 'elements.collecting', 'elements.intents', 'elements.injection', 'elements.conversion'],
  function (hellobar,
            templating, dom, site, environment, preview, coloring, format, capabilities, bus,
            elementsVisibility, elementsCollecting, elementsIntents, elementsInjection, elementsConversion) {

    const maxSliderSize = 380;

    const idTypeMap = {
      'hellobar-bar': 'bar',
      'hellobar-modal': 'modal',
      'hellobar-slider': 'slider',
      'hellobar-takeover': 'takeover',
      'hellobar-custom': 'custom'
    };

    let iosFocusInterval = null;

    class SiteElement {

      constructor(props) {
        for (var key in props) {
          this[key] = props[key];
        }
      }

      frameName() {
        return site.secret() + '-container-' + this.pageIndex;
      }

      setupIFrame(iframe) {
        if (this.animated)
          dom.addClass(iframe, "hb-animated");

        if (this.theme.id)
          dom.addClass(iframe, this.theme.id);

        // Any view_condition including string 'intent' will run the intent event listeners
        if (this.view_condition.indexOf('intent') !== -1) {
          elementsIntents.initializeIntentListeners();
        }

        // Starts setIntervals that check display setting conditions
        this.checkForDisplaySetting();
      }

      imagePlacementClass() {
        if (!!this.image_url) {
          return 'image-' + this.image_placement;
        } else {
          return '';
        }
      }

      imageFor(location, options) {
        var that = this;
        options = options || {};
        function imageSrc() {
          return that.image_url ? that.image_url : options.defaultImgSrc;
        }

        var locationIndex = location.indexOf(this.image_placement);
        if (!options.defaultImgSrc && (!this.image_url || locationIndex === undefined || locationIndex === -1)) {
          return '';
        }
        else if (this.image_placement == 'background') {
          return '<div class="hb-image-wrapper ' + this.image_placement + '" style="background-image:url(' + imageSrc() + ');></div>';
        } else {
          var imgClasses = [];
          (!options.themeType || options.themeType === 'generic') && imgClasses.push('uploaded-image');
          (options.classes) && imgClasses.push(options.classes);
          return '<div class="hb-image-wrapper ' + this.image_placement
            + '"><div class="hb-image-holder hb-editable-block hb-editable-block-image"><img class="'
            + imgClasses.join(' ')
            + '" src="' + imageSrc() + '" /></div></div>';
        }
      }

      blockContent(blockId) {
        var blocks = this.blocks || [];
        var foundBlock = null;
        for (var i = 0; i < blocks.length; i++) {
          if (blocks[i].id === blockId) {
            foundBlock = blocks[i];
          }
        }
        return (foundBlock && foundBlock.content) ? foundBlock.content : {};
      }

      setCSS(css) {
        this.css = css;
      }

      attach() {
        var that = this;
        if (environment.isIEXOrLess(9)) {
          this.animated = false;
        }

        function generateHtml() {

          var template = '';
          if (that.theme && that.theme.type === 'template') {
            var templateName = that.type.toLowerCase() + '_' + that.theme.id.replace(/\-/g, '_');
            template = templating.getTemplateByName(templateName);
          } else {
            template = templating.getTemplateByName(that.template_name);
          }
          return templating.renderTemplate(template, that);
        }

        var html = generateHtml();
        if (this.type === 'Custom') {
          var customJs = this.custom_js || '';
          html = html + '<script>var hbElement=parent.hellobar(\'elements\').findById(' + this.id + '); ' + customJs + '<\/script>'
        }
        // Once the dom is ready we inject the html returned from renderTemplate
        dom.runOnDocumentReady(function () {

          // Set an arbitrary timeout to prevent some rendering
          // conflicts with certain sites
          setTimeout(function () {
            this.injectSiteElementHTML(html);
            this.setIosKeyboardHandlers();
            this.setPullDown();

            // Monitor zoom scale events
            !(this.type === 'Custom') && this.hideOnZoom();

            // Set wiggle listeners
            if (this.wiggle_button.length > 0)
              dom.wiggleEventListeners(this.w);

            this.useGoogleFont();
            if (preview.isActive()) {
              const brandingLink = this.w.contentDocument.querySelector('.js-branding');
              brandingLink.addEventListener('click', (event) => event.preventDefault());
              this.useFroala();
            }
          }.bind(this), 1);
        }.bind(this));
      }

      // Injects the specified HTML for the given siteElement into the page
      injectSiteElementHTML(html) {
        var that = this;
        // Remove the containing iframe element if it exists
        if (this.w && this.w.parentNode) {
          this.w.parentNode.removeChild(this.w);
        }

        // Remove the pull-down element (for this particular site_element)
        const pullDown = document.querySelector('#pull-down.se-' + this.id);
        if (pullDown) {
          pullDown.parentNode.removeChild(pullDown);
        }

        // Create the iframe container
        this.w = document.createElement('iframe');
        this.w.src = 'about:blank';
        this.w.id = site.secret() + '-container';
        this.w.className = 'HB-' + this.type;
        this.w.name = this.frameName();
        dom.hideElement(this.w); // Start all site elements as hidden

        this.setupIFrame(this.w);

        const prepareStyle = () =>
          this.css
            ? '<style>' + this.css.split('hellobar-logo-wrapper').join('hellobar-logo-wrapper_' + site.secret()) + '</style>'
            : '';

        // Inject the container into the DOM
        elementsInjection.inject(this.w);
        // Render the siteElement in the container.
        var d = this.w.contentWindow.document;
        d.open();
        d.write('<html><head>' + prepareStyle() + '</head><body>' + html + '</body></html>');
        d.close();
        d.body.className = this.type;

        // Make HelloBar JS Core accessible to inner (iframe) document event handlers
        this.w.contentWindow.hellobar = hellobar;

        if (this.theme.id) {
          dom.addClass(d.body, this.theme.id);
        }

        if (preview.isActive()) {
          dom.addClass(d.body, 'preview-mode');
        }

        // Add IE Specific class overrides
        environment.isIEXOrLess(9) && dom.addClass(d.body, 'hb-old-ie');
        environment.isIE11() && dom.addClass(d.body, 'hb-paused-animations-ie')

        var adjustmentHandler = function () {
          that.adjustForCurrentWidth();
        };

        // This will do initial readjustment (with minimal time delay)
        setTimeout(adjustmentHandler, 1);

        // This interval will execute additional delayed readjustments
        // (we need this because we don't know exact moment of time when readjustment should happen,
        // because we can have animations etc)
        this.adjustmentInterval = setInterval(adjustmentHandler, 500);

        // Besides that we'll execute readjustment procedure when window size changes
        this.onWindowResize = function () {
          that.adjustForCurrentWidth();
        }.bind(this);
        window.addEventListener('resize', this.onWindowResize);
      }

      /**
       * Makes adjustments for the current window width
       */
      adjustForCurrentWidth() {
        var thisElement = this.getSiteElementDomNode();

        // Monitor siteElement height to update HTML/CSS
        if (thisElement) {
          if (thisElement.clientHeight) {
            var isMobile = environment.isMobileWidth(this);
            // Update the CSS class based on the width
            dom.setClass(thisElement, 'mobile', isMobile);

            // Adjust the container size
            this.setContainerSize(this.w, thisElement, this.type, isMobile);

            this.performElementTypeSpecificAdjustment && this.performElementTypeSpecificAdjustment();
          }
        }
      }

      setContainerSize(container, element, type, isMobile) {
        if (!container) {
          return;
        }

        if (preview.isActive()) {
          container.style.display = 'block';
          container.style.position = 'absolute';
          container.style.width = '100%';
          container.style.height = '100%';
          container.style.maxHeight = 'none';
          container.style.top = 0;
          container.style.bottom = 0;
          container.style.left = 0;
          container.style.right = 0;
        } else {
          if (type === 'Bar') {
            container.style.maxHeight = (element.clientHeight + 8) + 'px';
          } else if (type === 'Slider') {
            var containerWidth = window.innerWidth;
            var newWidth = Math.min(maxSliderSize + 24, containerWidth - 24);
            container.style.width = newWidth + 'px';
            container.style.height = (element.clientHeight + 124) + 'px';
          }
        }
      }

      getSiteElementDomNode() {
        var el;
        if (this.w && this.w.contentDocument) {
          for (var key in idTypeMap) {
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
      }


      // Reads the site element's view_condition setting and calls hide/show per selected behavior
      // if viewCondition is missing or badly formed, siteElement displays immediately by default

      checkForDisplaySetting() {
        var viewCondition = this.view_condition;
        var originalDisplay = this.w.style.display;

        if (document.getElementById('hellobar-preview-container') !== null)
          viewCondition = 'preview';

        var show = function () {
          clearInterval(this.displayCheckInterval);
          dom.showElement(this.w);

          // Track the view
          if (!this.dontRecordView) {
            elementsConversion.viewed(this);
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
            dom.animateIn(this.w)
          }

        }.bind(this);

        var showMinimizedBar = function () {
          dom.hideElement(this.w);
          this.pullDown && dom.animateIn(this.pullDown);
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
            elementsIntents.scrollTargetCheck(300, show);
          }, 500);
        }
        else if (viewCondition === 'scroll-middle') {
          this.displayCheckInterval = setInterval(function () {
            elementsIntents.scrollTargetCheck("middle", show);
          }, 500);
        }
        else if (viewCondition === 'scroll-to-bottom') {
          this.displayCheckInterval = setInterval(function () {
            elementsIntents.scrollTargetCheck("bottom", show);
          }, 500);
        }
        else if (viewCondition === 'exit-intent') {
          this.displayCheckInterval = setInterval(function () {
            elementsIntents.intentCheck("exit", show);
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
      }

      hideOnZoom() {
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
      }

      remove() {
        this.onWindowResize && window.removeEventListener('resize', this.onWindowResize);
        this.adjustmentInterval && clearInterval(this.adjustmentInterval);
        if (this.w != null && this.w.parentNode != null) {
          this.w.parentNode.removeChild(this.w);
          // Note: this should really clean up event listeners
          // and timers too
          return true;
        }
        return false;
      }

      close() {
        if (preview.isActive()) {
          return;
        }
        dom.animateOut(this.w, this.onClosed.bind(this));
      }

      onClosed() {
        // Remove the element
        if (this.remove()) {
          elementsVisibility.setVisibilityControlCookie('dismiss', this);
        }

        bus.trigger('hellobar.elements.closed', this);
      }

      // Create the pulldown arrow element for when a bar/slider is hidden
      // The pulldown arrow is only created when a site element is closable
      setPullDown() {
        // Create the pull down elements
        if (this.closable) {
          var pullDown = document.createElement("div");
          pullDown.id = "pull-down";
          pullDown.style.backgroundColor = "#" + this.background_color;
          pullDown.className = "hb-" + this.size + " hellobar " + "hb-" + this.placement + ' se-' + this.id;

          if (coloring.colorIsBright(this.primary_color)) {
            pullDown.className += ' inverted';
          }

          var pdLink = document.createElement("div");
          pdLink.className = "hellobar-arrow";
          pdLink.onclick = function () {
            dom.animateIn(this.w);
            dom.animateOut(this.pullDown);

            // expire (i.e. delete) the VisibilityControl cookie
            // (because the user has asked the bar to be shown again)
            elementsVisibility.expireVisibilityControlCookie('dismiss', this.id);

            this.onPullDownSet && this.onPullDownSet();

          }.bind(this);

          var svgArrow = '<svg xmlns="http://www.w3.org/2000/svg" width="11px" height="11px" viewBox="43.6 92.5 315 315"><path d="M49.6 92.5c-3.3 0-6 2.7-6 6v303c0 3.3 2.7 6 6 6h303c3.3 0 6-2.7 6-6v-303c0-3.3-2.7-6-6-6H49.6zM229.6 254.3c-3.3 0-6 2.7-6 6V360c0 3.3-2.7 6-6 6h-33c-3.3 0-6-2.7-6-6v-99.7c0-3.3-2.7-6-6-6H99.2c-3.3 0-4.2-2-2-4.5l99.9-111.4c2.2-2.5 5.8-2.5 8 0l99.9 111.4c2.2 2.5 1.3 4.5-2 4.5H229.6z"/></svg>';
          pdLink.innerHTML = svgArrow;

          pullDown.appendChild(pdLink);
          elementsInjection.inject(pullDown);
          this.pullDown = pullDown;
        }
      }

      setIosKeyboardHandlers() {
        if (!environment.isMobileSafari()) {
          return;
        }

        var inputs = this.w.contentDocument.getElementsByTagName("input");
        for (var i = 0; i < inputs.length; i++) {
          inputs[i].addEventListener("focus", this.iosKeyboardShow.bind(this));
          inputs[i].addEventListener("blur", this.iosKeyboardHide.bind(this));
        }
      }

      iosKeyboardShow(e) {
        e.preventDefault();
        var element = this;

        if (this.type == "Bar") {
          iosFocusInterval = setTimeout(function () {
            window.scrollTo(0, element.w.offsetTop);
          }, 500);
        }
        else if (this.type == "Slider") {
          this.w.style.position = "fixed";
          iosFocusInterval = setInterval(function () {
            element.w.style.left = window.pageXOffset + "px";
            element.w.style.top = window.pageYOffset + "px";
          }, 200);
        }
        else if (this.type == "Takeover" || this.type == "Modal" || this.type == "Custom") {
          this.updateStyleFor(false);
        }
      }

      iosKeyboardHide(e) {
        e.preventDefault();

        if (iosFocusInterval != null) {
          clearInterval(iosFocusInterval);
          iosFocusInterval = null;
        }

        if (this.type == "Takeover" ||
          this.type == "Modal" ||
          this.type == "Slider" ||
          this.type == "Custom") {
          this.updateStyleFor(true);
        }
      }

      updateStyleFor(reset) {
        var element = this;
        var contentDocument = element.w.contentDocument;
        var hbModal = contentDocument.getElementById('hellobar-modal') || contentDocument.getElementById('hellobar-takeover') || contentDocument.getElementById('hellobar-custom');

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

          if (this.type == 'Slider') {
            element.w.style.position = "fixed";
          } else {
            element.w.style.position = "absolute";
          }

          iosFocusInterval = setInterval(function () {
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
          }, 500);

          hbModal.scrollIntoView();
          contentDocument.getElementsByClassName('hb-content-wrapper')[0].scrollIntoView();
          window.scrollTo(0, window.innerHeight / 2);
        }
        return false;
      }

      // Necessary convenience method for saying this
      // SiteElement has converted (used in templates)
      converted() {
        elementsConversion.converted(this);
      }

      useGoogleFont() {
        if (!this.google_font) return;
        var head = this.w.contentWindow.document.getElementsByTagName('head')[0];

        var link = this.w.contentWindow.document.createElement("LINK");
        link.href = 'https://fonts.googleapis.com/css?family=' + this.google_font;
        link.rel = 'stylesheet';
        link.type = 'text/css';

        head.appendChild(link);

        // if is mobile safari, prevent from zooming
        if (environment.isMobileSafari()) {
          var meta = this.w.contentWindow.document.createElement("META");
          meta.name = "viewport";
          meta.content = "width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no";
          head.appendChild(meta);
        }
      }

      addCss(href) {
        var head = this.w.contentWindow.document.getElementsByTagName('head')[0];
        var link = this.w.contentWindow.document.createElement("LINK");
        link.href = href;
        link.rel = 'stylesheet';
        link.type = 'text/css';
        head.appendChild(link);
      }

      addJs(href) {
        var head = this.w.contentWindow.document.getElementsByTagName('head')[0];
        var script = this.w.contentWindow.document.createElement("SCRIPT");
        script.src = href;
        script.type = 'text/javascript';
        head.appendChild(script);
      }

      useFroala() {
        this.addCss('//cdnjs.cloudflare.com/ajax/libs/font-awesome/4.4.0/css/font-awesome.min.css');
        this.addCss('//cdnjs.cloudflare.com/ajax/libs/froala-editor/2.4.0/css/froala_editor.min.css');
        //removeing this and cherry picking styles in common.css
        //this.addCss('//cdnjs.cloudflare.com/ajax/libs/froala-editor/2.4.0/css/froala_style.css');
        this.addCss('//cdnjs.cloudflare.com/ajax/libs/froala-editor/2.4.0/css/plugins/colors.min.css');
        this.addCss('//cdnjs.cloudflare.com/ajax/libs/froala-editor/2.4.0/css/plugins/emoticons.css');
        this.addCss('//cdnjs.cloudflare.com/ajax/libs/froala-editor/2.4.0/css/plugins/image.min.css');
      }

      brightnessClass() {
        if (this.getBrightness(this.background_color) < 0.25) //an empirical value most suitable for all backgrounds
          return "dark";
        else
          return "light";
      }

      //get brightness of site element by its background color using specific formula from "preview-controller.coffee" file
      getBrightness(x) {
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

      handleCtaClick() {
        if (preview.isActive()) {
          return false;
        } else {
          elementsCollecting.submitEmail(this,
            this.w.contentDocument.getElementById('hb-fields-form'),
            null, null, this.email_redirect,
            this.settings.redirect_url, 'thank-you');
          return false;
        }
      }

      thankYouMessage() {
        return this.unquotedValue('thank_you_text', 'Thank you for signing up!');
      }

      unquotedValue(propertyName, defaultValue) {
        var value = this[propertyName] || defaultValue;
        return (value && value.indexOf('\'') === 0) ? value.substring(1, value.length - 1) : value;
      }

      accountCssClass() {
        return this.use_free_email_default_msg ? 'free-account' : 'paid-account';
      }

      brandingCssClass() {
        // TODO REFACTOR do we need to get rid of 'no_b' capability?
        return (format.asBool(this.show_branding) || !capabilities.has('no_b')) ? 'show-branding' : 'dont-show-branding';
      }

      closableCssClass() {
        return this.closable ? 'closable' : '';
      }

      questionOrAnswerIsShown() {
        return format.asBool(this.questionified) || preview.getAnswerToDisplay();
      }

      renderBranding() {
        const template = templating.getTemplateByName('branding_animated');
        return templating.renderTemplate(template, this);
      }

      brandingName() {
        return 'animated';
      }

      shouldShowBranding() {
        return this.show_branding;
        // TODO initially it was HB.t(siteElement.show_branding) || !HB.CAP.no_b
      }

    }

    return SiteElement;

  });
