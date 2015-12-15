HB.SliderElement = HB.createClass({
  initialize: function(props)
  {
    this.callSuper('initialize', props);
    this.link_color = "FFFFFF";
  }, 

  setupIFrame: function(iframe)
  {
    this.callSuper('setupIFrame', iframe);
    HB.addClass(iframe, "hb-" + this.placement)
  }
}, HB.SiteElement);
