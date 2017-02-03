HB.SliderElement = HB.createClass({
  initialize: function (props) {
    this.callSuper('initialize', props);
  },

  setupIFrame: function (iframe) {
    this.callSuper('setupIFrame', iframe);
    HB.addClass(iframe, "hb-" + this.placement)
  },

  minimize: function () {
    HB.animateOut(this.w, this.onHidden());

    if (HB.p) {
      HB.p.style.display = 'none';
    }

    HB.animateIn(this.pullDown);
  },

  // set visibility control cookie (see similar code in bar.js)
  onHidden: function () {
    HB.setVisibilityControlCookie('dismiss', this);
  }

}, HB.SiteElement);
