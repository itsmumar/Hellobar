hellobar.defineModule('elements.class.slider',
  ['base.dom', 'elements.class', 'elements.visibility'],
  function (dom, SiteElement, elementsVisibility) {

    class SliderElement extends SiteElement {
      constructor(props) {
        super(props);
      }

      setupIFrame(iframe) {
        super.setupIFrame(iframe);
        dom.addClass(iframe, 'hb-' + this.placement);
      }

      minimize() {
        dom.animateOut(this.w, this.onHidden());
        dom.animateIn(this.pullDown);
      }

      // set visibility control cookie (see similar code in bar.js)
      onHidden() {
        elementsVisibility.setVisibilityControlCookie('dismiss', this);
      }

    }

    return SliderElement;
  });
