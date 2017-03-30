hellobar.defineModule('elements.class.bar',
  ['base.dom', 'base.format', 'base.environment', 'elements.class', 'elements.injection', 'elements.visibility'],
  function (dom, format, environment, SiteElement, elementsInjection, elementsVisibility) {

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
        if (this.pusher) {
          this.pusher.parentNode.removeChild(this.pusher);
        }

        this.pusher = null;

        // Create the pusher (which pushes the page down) if needed
        if (format.asBool(this.pushes_page_down)) {
          this.pusher = document.createElement('div');
          this.pusher.id = 'hellobar-pusher';
          this.pusher.className = 'hb-' + this.size;

          // shrinks pusher if siteElement hidden by viewCondition rules
          if (this.w.style.display === 'none') {
            this.pusher.style.height = 0;
          }

          elementsInjection.inject(this.pusher, this.placement === 'bar-bottom');
        }
      }

      minimize() {
        dom.animateOut(this.w, this.onHidden());

        if (this.pusher) {
          this.pusher.style.display = 'none';
        }

        dom.animateIn(this.pullDown);
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
