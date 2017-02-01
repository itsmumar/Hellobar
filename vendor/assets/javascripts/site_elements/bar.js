HB.BarElement = HB.createClass({
  initialize: function (props) {
    this.callSuper("initialize", props);
  },

  setupIFrame: function (iframe) {
    this.callSuper('setupIFrame', iframe)
    HB.addClass(iframe, "hb-" + this.size);
    HB.addClass(iframe, "hb-" + this.placement);
    HB.addClass(iframe, (HB.t(this.remains_at_top) ? " remains-in-place" : ""));

    if (this.animated) {
      HB.addClass(iframe, "hellobar");
    }

    iframe.scrolling = "no";
    iframe.setAttribute("frameBorder", 0); // IE 9 and less

    // Remove the pusher if it exists
    if (HB.p) {
      HB.p.parentNode.removeChild(HB.p);
    }

    HB.p = null;

    // Create the pusher (which pushes the page down) if needed
    if (HB.t(this.pushes_page_down)) {
      HB.p = document.createElement("div");
      HB.p.id = "hellobar-pusher";
      HB.p.className = "hb-" + this.size;

      // shrinks pusher if siteElement hidden by viewCondition rules
      if (this.w.style.display === "none") {
        HB.p.style.height = 0
      }

      HB.injectAtTop(HB.p, this.placement == "bar-bottom");
    }
  },

  minimize: function () {
    HB.animateOut(this.w, this.onHidden());

    if (HB.p != null)
      HB.p.style.display = 'none';

    if (HB.colorIsBright(this.primary_color)) {
      $(this.pullDown).addClass('inverted');
    }

    HB.animateIn(this.pullDown);
  },

  onHidden: function () {
    // Track specific elements longer, for takeovers/modals
    var expiration, cookie_name, cookie_str, dismissed_elements;
    // Track specific elements 24 hours, for bars/sliders
    expiration = 86400000; // 24 hours
    cookie_name = "HBDismissedBars";
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

    // The above HBDismissedBars cookie is currently being *ignored* when
    // displaying a bar (dead code) so instead set a regular visibility cookie
    // based on user settings
    HB.setVisibilityControlCookie('dismiss', this);
  },

  attach: function () {
    // Disable wiggle on Mobile Safari because it blocks the click action
    if (this.wiggle_button && !HB.isMobileSafari()) {
      this.wiggle = 'wiggle';
    } else {
      this.wiggle = '';
    }

    this.callSuper('attach')
  }

}, HB.SiteElement);
