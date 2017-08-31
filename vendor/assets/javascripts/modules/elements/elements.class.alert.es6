hellobar.defineModule('elements.class.alert',
  ['hellobar', 'base.dom', 'base.cdn', 'base.cdn.libraries', 'base.site', 'base.format', 'base.templating',
    'base.preview', 'base.coloring',
    'elements.injection', 'elements.visibility', 'elements.intents', 'elements.conversion', 'elements.class'],
  function (hellobar, dom, cdn, cdnLibraries, site, format, templating,
            preview, coloring,
            elementsInjection, elementsVisibility, elementsIntents, elementsConversion, SiteElement) {

    const geometry = {
      offset: 10,
      triggerWidth: 60,
      maxPopupWidth: 380
    };

    /**
     * @class Trigger
     * Trigger part (a bell or whatever) of Alert element type.
     */
    class Trigger {
      constructor(iframe, model) {
        this._domNode = iframe.contentDocument.getElementById('hb-trigger');
        this._model = model;
        this._clickListener = null;
        this._onClick = () => {
          this._clickListener && this._clickListener();
        };
        this._subscribe();
        this.showMainIcon();
      }

      setClickListener(listener) {
        this._clickListener = listener;
      }

      _subscribe() {
        this._domNode.addEventListener('click', this._onClick);
      }

      _unsubscribe() {
        this._domNode.removeEventListener('click', this._onClick);
      }

      _mainIconDomNode() {
        return this._domNode.querySelector('.js-main-icon');
      }

      _closeIconDomNode() {
        return this._domNode.querySelector('.js-close-icon');
      }

      showMainIcon() {
        dom.hideElement(this._closeIconDomNode(), 'inline-block');
        dom.showElement(this._mainIconDomNode(), 'inline-block');
      }

      showCloseIcon() {
        dom.hideElement(this._mainIconDomNode(), 'inline-block');
        dom.showElement(this._closeIconDomNode(), 'inline-block');
      }

      adjustSize() {
        const applyPlacement = () => {
          const offset = preview.isActive() ? (geometry.offset + 'px') : 0;

          const applyBottomLeftPlacement = () => {
            dom.setStyles(this._domNode, {
              left: offset,
              bottom: offset,
              top: 'auto',
              right: 'auto'
            });
          };

          const applyBottomRightPlacement = () => {
            dom.setStyles(this._domNode, {
              left: 'auto',
              bottom: offset,
              top: 'auto',
              right: offset
            });
          };

          (this._model.placement === 'bottom-right') ? applyBottomRightPlacement() : applyBottomLeftPlacement();
        };
        const applyBorder = () => {
          const border = (this._model.trigger_color && (this._model.trigger_color.toLowerCase() === 'ffffff')) ?
            `1px solid #${this._model.trigger_icon_color}` :
            'none';
          dom.setStyles(this._domNode, {border});
        };
        applyPlacement();
        applyBorder();
      }

      animate() {
        const iconDomElement = this._domNode.querySelector('.js-main-icon');
        dom.removeClass(iconDomElement, 'animated');
        setTimeout(() => {
          dom.addClass(iconDomElement, 'animated');
          iconDomElement && iconDomElement.addEventListener("animationend", () => dom.removeClass(iconDomElement, 'animated'), false);
        });
      }

      remove() {
        this._unsubscribe();
      }
    }

    /**
     * @class Popup
     * Popup (collapsible slider) part of Alert element type.
     */
    class Popup {
      constructor(iframe, model) {
        this._domNode = iframe.contentDocument.getElementById('hellobar-slider');
        this._model = model;
      }

      adjustSize() {
        const applyPlacement = () => {
          const horizontalOffset = (preview.isActive() ? geometry.offset : 0) + 3 + 'px';
          const verticalOffset = (preview.isActive() ? 10 : 0) + (geometry.offset + geometry.triggerWidth + geometry.offset) + 'px';
          const maxWidth = (geometry.maxPopupWidth - 6) + 'px'; // 6px for shadows

          const applyBottomLeftPlacement = () => {
            dom.setStyles(this._domNode, {
              top: 'auto',
              left: horizontalOffset,
              bottom: verticalOffset,
              maxWidth: maxWidth
            });
          };

          const applyBottomRightPlacement = () => {
            dom.setStyles(this._domNode, {
              right: horizontalOffset,
              top: 'auto',
              bottom: verticalOffset,
              maxWidth: maxWidth
            });
          };

          (this._model.placement === 'bottom-right') ? applyBottomRightPlacement() : applyBottomLeftPlacement();
        };

        applyPlacement();
      }

      show() {
        dom.showElement(this._domNode);
      }

      hide() {
        dom.hideElement(this._domNode);
      }

      remove() {
      }
    }

    /**
     * A class for managing audio element inside the Alert.
     */
    class Audio {
      constructor(iframe, model) {
        this._domNode = iframe.contentDocument.getElementsByTagName('audio')[0];
        this._model = model;
      }

      play() {
        (this._model.sound !== 'none') && this._domNode.play();
      }
    }

    class ConversionHelper {
      constructor(alertElement) {
        this._element = alertElement;
        this._wasConverted = false;
        this._wasViewed = false;
      }

      converted() {
        if (!this._wasConverted) {
          elementsConversion.converted(this._element);
          this._wasConverted = true;
        }
      }

      viewed() {
        if (!this._wasViewed) {
          elementsConversion.viewed(this._element);
          this._wasViewed = true;
        }
      }
    }

    // ----- A few iframe-related functions ------------------------

    function createIFrame() {
      const iframe = document.createElement('iframe');

      iframe.src = 'about:blank';
      iframe.id = site.secret() + '-container';
      iframe.className = 'HB-Alert';
      iframe.name = iframe.id;

      dom.hideElement(iframe);

      return iframe;
    }

    function populateIFrame(iframe, css, bodyHtml) {
      const prepareStyle = () =>
        css ? '<style>' + css.split('hellobar-logo-wrapper').join('hellobar-logo-wrapper_' + site.secret()) + '</style>'
          : '';
      const documentContent = () => {
        return '<html><head>' + prepareStyle() + '</head><body>' + bodyHtml + '</body></html>';
      };
      var iframeDocument = iframe.contentDocument;
      iframeDocument.open();
      iframeDocument.write(documentContent());
      iframeDocument.close();
      iframeDocument.body.className = 'alert';
    }

    function configureIFrame(iframe, model) {
      model.animated && dom.addClass(iframe, 'hb-animated');
      if (model.theme && model.theme_id) {
        dom.addClass(iframe, model.theme_id);
      }
    }

    function adjustIFrameForPreview(iframe) {
      dom.setStyles(iframe, {
        display: 'block',
        position: 'absolute',
        width: '100%',
        height: '100%',
        maxHeight: 'none',
        top: 0,
        bottom: 0,
        left: 0,
        right: 0
      });
    }

    function adjustIFrameForSite(iframe, alertElement) {
      const elementIsVisible = alertElement.isVisible();
      const popupIsVisible = alertElement.isPopupVisible();
      const placement = alertElement._model.placement;
      const forVisible = () => {
        const offset = geometry.offset + 'px';
        const maxPopupWidth = geometry.maxPopupWidth;
        // Add border thickness to trigger size
        const triggerWidth = (geometry.triggerWidth + 2);
        const alertElementHeight = alertElement.contentDocument().querySelector('#hellobar-slider').clientHeight;

        dom.setStyles(iframe, {
          display: 'block',
          position: 'fixed',
          left: placement === 'bottom-right' ? 'auto' : offset,
          right: placement === 'bottom-right' ? offset : 'auto',
          width: (popupIsVisible ? maxPopupWidth : triggerWidth) + 'px',
          top: 'auto',
          bottom: offset,
          height: (popupIsVisible ? alertElementHeight + 124 : triggerWidth) + 'px',
          border: 'none'
        });

        dom.addClass(iframe, 'hb-animateIn');
      };
      const forHidden = () => {
        dom.setStyles(iframe, {
          display: 'none'
        });
      };
      elementIsVisible ? forVisible() : forHidden();
    }

    /**
     * @class AlertElement
     * JavaScript API for Alert site element type.
     * @module
     */
    class AlertElement extends SiteElement {
      constructor(model) {
        super();
        this._model = model;
        this._isPopupVisible = false;
        this._isVisible = false;
        this._isNotified = false;
        this._onCtaClicked = (evt) => {
          this._conversionHelper.converted();
          evt.preventDefault();
          evt.stopPropagation();
        };
      }

      model() {
        return this._model;
      }

      get id() {
        return this._model.id;
      }

      contentDocument() {
        return this._iframe.contentDocument;
      }

      attach() {
        const html = () => {
          const template = templating.getTemplateByName(this._model.template_name);
          return templating.renderTemplate(template, {siteElement: this});
        };
        const addCdnResources = (doc) => {
          cdnLibraries.useFontAwesome(doc);
          preview.isActive() && cdnLibraries.useFroala(doc);
          if (this._model.google_font) {
            cdn.addCss('https://fonts.googleapis.com/css?family=' + this._model.google_font, this._iframe.contentDocument);
          }
        };
        const bindEvents = () => {
          const ctaElement = this._iframe.contentDocument.querySelector('.js-cta');
          ctaElement && ctaElement.addEventListener('click', this._onCtaClicked);
        };
        const onTriggerClicked = () => {
          this._isNotified = true;
          if (this._isPopupVisible) {
            this.hidePopup();
          } else {
            this.showPopup();
          }
        };
        const mainInitializationCycle = () => {
          this._iframe = createIFrame(this._model.type);
          elementsInjection.inject(this._iframe);
          populateIFrame(this._iframe, this._css, html());
          configureIFrame(this._iframe, this._model);
          this._iframe.contentWindow.hellobar = hellobar;
          preview.isActive() && dom.addClass(this._iframe.contentDocument.body, 'preview-mode');
          this._model.theme && dom.addClass(this._iframe.contentDocument.body, this._model.theme_id);
          addCdnResources(this._iframe.contentDocument);
          this._trigger = new Trigger(this._iframe, this._model);
          this._popup = new Popup(this._iframe, this._model);
          this._audio = new Audio(this._iframe, this._model);
          this._conversionHelper = new ConversionHelper(this);
          this._trigger.setClickListener(onTriggerClicked);
          this.adjustSize();
          bindEvents();
          elementsIntents.applyViewCondition(this._model.view_condition, () => {
            this.show();

            // initial ringing delay (to let animation finish) [ms]
            let delay = 1500;

            if (this._model.notification_delay > 0) {
              delay += this._model.notification_delay * 1000;
            }

            setTimeout(() => {
              this.notify();
            }, delay);

          }, () => {
            this.show();
          });
          this.onInit && this.onInit();
        };
        dom.runOnDocumentReady(() => {
          setTimeout(() => {
            mainInitializationCycle();
            preview.isActive() && this.showPopup();
          }, 1);
        });
      }

      adjustSize() {
        if (preview.isActive()) {
          adjustIFrameForPreview(this._iframe);
        } else {
          adjustIFrameForSite(this._iframe, this);
        }

        this._trigger.adjustSize();
        this._popup.adjustSize();
      }

      _domNodeById(id) {
        return this._iframe.contentDocument.getElementById(id);
      }

      _elementDomNode() {
        return this._domNodeById('hellobar-alert');
      }

      _popupContainerDomNode() {
        return this._domNodeById('hb-popup-container');
      }

      setCSS(css) {
        this._css = css;
      }

      isPopupVisible() {
        return this._isPopupVisible;
      }

      close() {
        this.hidePopup();
      }

      showPopup() {
        this._isPopupVisible = true;
        this._trigger.showCloseIcon();
        dom.showElement(this._popupContainerDomNode(), 'block');
        this.adjustSize();
        this._conversionHelper.viewed();
        this.onShowPopup && this.onShowPopup();
      }

      hidePopup() {
        this._isPopupVisible = false;
        this._trigger.showMainIcon();
        dom.hideElement(this._popupContainerDomNode(), 'block');
        this.adjustSize();
        this.onHidePopup && this.onHidePopup();
      }

      isVisible() {
        return this._isVisible;
      }

      show() {
        if (this._isVisible) {
          // It's already visible, nothing to show
          return;
        }
        this._isVisible = true;
        this.adjustSize();
      }

      hide() {
        if (!this._isVisible) {
          // It's already hidden, nothing to hide
          return;
        }
        this._isVisible = false;
        this.adjustSize();
      }

      notify() {
        if (this._isNotified) {
          return;
        }
        this._isNotified = true;

        elementsVisibility.setVisibilityControlCookie('dismiss', this);
        this._audio.play();
        this._trigger.animate();
      }

      remove() {
        const unbindEvents = () => {
          if (this._iframe) {
            const ctaElement = this._iframe.contentDocument.querySelector('.js-cta');
            ctaElement && ctaElement.removeEventListener('click', this._onCtaClicked);
          }
        };
        unbindEvents();
        this._trigger && this._trigger.remove();
        this._popup && this._popup.remove();
        this._iframe && this._iframe.remove();
        this.onRemove && this.onRemove();
      }

      cssClasses() {
        const that = this;
        return {
          brightness: () => coloring.colorIsBright(that._model.background_color) ? 'light' : 'dark'
        };
      }

      onInit() {
      }

      onShowPopup() {
      }

      onHidePopup() {
      }

      onRemove() {
      }

    }

    return AlertElement;

  });
