HB.SliderElement = HB.createClass({
  initialize: function (props) {
    this.callSuper('initialize', props);
  },

  setupIFrame: function (iframe) {
    this.callSuper('setupIFrame', iframe);
    HB.addClass(iframe, "hb-" + this.placement)
  }
}, HB.SiteElement);
