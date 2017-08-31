hellobar.defineModule('elements.class.bar',
  ['base.dom', 'base.format', 'base.environment', 'elements.class', 'elements.injection', 'elements.visibility'],
  function (dom, format, environment, SiteElement, elementsInjection, elementsVisibility) {

    let pusher = null;

    class BarElement extends SiteElement {
      constructor(props) {
        super(props);
      }

      setupIFrame(iframe) {
        super.setupIFrame(iframe);
        dom.addClass(iframe, 'hb-' + this.size);
        dom.addClass(iframe, 'hb-' + this.placement);
        dom.addClass(iframe, (format.asBool(this.remains_at_top) ? ' remains-in-place' : ''));

        if (this.animated) {
          dom.addClass(iframe, 'hellobar');
        }

        iframe.scrolling = 'no';
        iframe.setAttribute('frameBorder', 0); // IE 9 and less

        // Remove the pusher if it exists
        if (pusher) {
          pusher.parentNode.removeChild(pusher);
        }

        pusher = null;

        // Create the pusher (which pushes the page down) if needed
        if (format.asBool(this.pushes_page_down)) {
          pusher = document.createElement('div');
          pusher.id = 'hellobar-pusher';
          pusher.className = 'hb-' + this.size;

          // shrinks pusher if siteElement hidden by viewCondition rules
          if (this.w.style.display === 'none') {
            pusher.style.height = 0;
          }

          elementsInjection.inject(pusher, this.placement === 'bar-bottom');
        }
      }

      minimize() {
        dom.animateOut(this.w, this.onHidden());

        if (pusher) {
          pusher.style.display = 'none';
        }

        dom.animateIn(this.pullDown);
      }

      onClosed() {
        if (pusher) {
          pusher.style.display = 'none';
        }
        super.onClosed();
      }

      onHidden() {
        elementsVisibility.setVisibilityControlCookie('dismiss', this);
      }

      attach() {
        // Disable wiggle on Mobile Safari because it blocks the click action
        if (this.wiggle_button && !environment.isMobileSafari()) {
          this.wiggle = 'wiggle';
        } else {
          this.wiggle = '';
        }

        super.attach();
      }

      performElementTypeSpecificAdjustment() {
        const domElement = this.getSiteElementDomNode();
        // Adjust the pusher
        if (pusher) {
          // handle case where display-condition check has hidden this.w
          if (this.w.style.display === 'none') {
            return;
          }
          var borderPush = format.asBool((this.show_border) ? 3 : 0);
          pusher.style.height = (domElement.clientHeight + borderPush) + 'px';
        }

        // Add multiline class
        var barBounds = (this.w.className.indexOf('regular') > -1 ? 32 : 52 );
        dom.setClass(domElement, 'multiline', domElement.clientHeight > barBounds);
      }

      onPullDownSet() {
        // if the pusher exists, unhide it since it should be hidden at this point
        if (this.pushes_page_down && pusher) {
          dom.showElement(pusher, '');
        }
      }

      barSizeCssClass() {
        const size = this.size;
        if (size === 'large' || size === 'regular') {
          return size;
        }
        var sizeAsInt = parseInt(size);
        if (sizeAsInt < 40) {
          return 'regular';
        } else if (sizeAsInt >= 40 && sizeAsInt < 70) {
          return 'large';
        } else {
          return 'x-large';
        }
      }

      barHeight() {
        const size = this.size;
        switch (size) {
          case 'large':
            return '50px';
          case 'regular':
            return '30px';
          default:
            return size + 'px';
        }
      }

    }

    return BarElement;
  });
