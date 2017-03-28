hellobar.defineModule('elements.class.slider', ['elements.class'], function (SiteElement) {

  class SliderElement extends SiteElement {
    initialize(props) {
      this.callSuper('initialize', props);
    }

    setupIFrame(iframe) {
      this.callSuper('setupIFrame', iframe);
      HB.addClass(iframe, "hb-" + this.placement)
    }

    minimize() {
      HB.animateOut(this.w, this.onHidden());
      HB.animateIn(this.pullDown);
    }

    // set visibility control cookie (see similar code in bar.js)
    onHidden() {
      HB.setVisibilityControlCookie('dismiss', this);
    }

  }

  return SliderElement;
});
