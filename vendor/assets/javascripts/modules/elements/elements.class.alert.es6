hellobar.defineModule('elements.class.alert',
  ['hellobar', 'base.dom', 'base.cdn.libraries', 'base.site', 'base.format', 'base.templating', 'base.environment', 'base.preview',
    'elements.injection', 'elements.visibility', 'elements.intents', 'elements.conversion'],
  function (hellobar, dom, cdnLibraries, site, format, templating, environment, preview,
            elementsInjection, elementsVisibility, elementsIntents, elementsConversion) {

    const geometry = {
      offset: 10,
      triggerSize: 60,
      maxPopupSize: 380
    };

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
          const offset = geometry.offset + 'px';
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
        applyPlacement();
      }

      animate() {
        animateWithSwinging(this._domNode);
      }

      remove() {
        this._unsubscribe();
      }
    }

    class Popup {
      constructor(iframe, model) {
        this._domNode = iframe.contentDocument.getElementById('hellobar-slider');
        this._model = model;
      }

      adjustSize() {
        const applyPlacement = () => {
          const horizontalOffset = geometry.offset + 'px';
          const verticalOffset = (geometry.offset + geometry.triggerSize + geometry.offset) + 'px';
          const applyBottomLeftPlacement = () => {
            dom.setStyles(this._domNode, {
              left: horizontalOffset,
              top: 'auto',
              right: 'auto',
              bottom: verticalOffset
            });
          };
          const applyBottomRightPlacement = () => {
            dom.setStyles(this._domNode, {
              left: 'auto',
              top: 'auto',
              right: horizontalOffset,
              bottom: verticalOffset
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

    class Audio {
      constructor(iframe, model) {
        this._domNode = iframe.contentDocument.getElementsByTagName('audio')[0];
        this._model = model;
      }

      play() {
        this._domNode.play();
      }
    }

    const iframeId = (() => {
      let index = 1;
      return () => site.secret() + '-container' + (index++);
    })();

    function createIFrame() {
      const id = iframeId();
      const iframe = document.createElement('iframe');
      iframe.src = 'about:blank';
      iframe.id = id;
      iframe.className = 'HB-alert';
      iframe.name = id;
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
      if (model.theme && model.theme.id) {
        dom.addClass(iframe, model.theme.id);
        dom.addClass(iframe.contentDocument.body, model.theme.id);
      }
    }

    function adjustIFrameForPreview(iframe) {
      iframe.style.display = 'block';
      iframe.style.position = 'absolute';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.style.maxHeight = 'none';
      iframe.style.top = 0;
      iframe.style.bottom = 0;
      iframe.style.left = 0;
      iframe.style.right = 0;
    }

    function adjustIFrameForSite(iframe, alertElement) {
      const elementIsVisible = alertElement.isVisible();
      const popupIsVisible = alertElement.isPopupVisible();
      const placement = alertElement.model.placement;
      const forVisible = () => {
        const offset = geometry.offset + 'px';
        const maxSliderWidth = geometry.maxPopupSize + 'px';
        const triggerWidth = geometry.triggerSize + 'px';
        dom.setStyles(iframe, {
          left: placement === 'bottom-right' ? 'auto' : offset,
          right: placement === 'bottom-right' ? offset : 'auto',
          width: popupIsVisible ? maxSliderWidth : triggerWidth,
          top: 'auto',
          bottom: offset,
          height: popupIsVisible ? window.innerHeight : triggerWidth
        });
      };
      const forHidden = () => {
        dom.setStyles(iframe, {
          display: 'none'
        });
      };
      elementIsVisible ? forVisible() : forHidden();
    }

    function animateWithSwinging(element) {
      const iterationLimit = 30;
      let iteration = 0;
      const originalTransform = element.style.transform;

      function iterate() {
        const rotationDegrees = Math.cos(iteration) * 30;
        element.style.transform = `rotate(${rotationDegrees}deg)`;
        iteration++;
        if (iteration < iterationLimit) {
          setTimeout(iterate, 80);
        } else {
          element.style.transform = originalTransform;
        }
      }

      iterate();
    }


    class AlertElement {
      constructor(model) {
        this.model = model;
        this._isPopupVisible = false;
        this._isVisible = false;
        this._onCtaClicked = (evt) => {
          elementsConversion.converted(this);
          evt.preventDefault();
          evt.stopPropagation();
        };
      }

      attach() {
        const html = () => {
          // TODO uncomment
          //const template = templating.getTemplateByName('alert');
          //return templating.renderTemplate(template, this);
          const sliderTemplate = '<div id="hellobar-slider"><div class="slider-content"><div class="hb-content-wrapper"><div class="hb-inner-content"><div class="hb-text-wrapper"><div class="hb-headline-text">Test headline</div><div class="hb-secondary-text">Test caption</div></div></div></div></div></div></div>';
          return `<div id="hellobar-alert" class="element"><audio src="https://s3.amazonaws.com/assets.hellobar.com/bell/ring2.mp3"></audio><div id="hb-trigger" class="trigger"><i class="fa fa-bell js-main-icon"></i><i class="fa fa-remove js-close-icon"></i></div><div id="hb-popup-container" style="display:none">${sliderTemplate}</div></div>`;
        };
        const addCdnResources = (doc) => {
          cdnLibraries.useFontAwesome(doc);
        };
        const bindEvents = () => {
          const ctaElement = this._iframe.contentDocument.querySelector('.js-cta');
          ctaElement && ctaElement.addEventListener('click', this._onCtaClicked);
        };
        const onTriggerClicked = () => {
          if (this._isPopupVisible) {
            this.hidePopup();
          } else {
            this.showPopup();
          }
          this._isPopupVisible = !this._isPopupVisible;
        };
        // TODO change this to proper CSS usage
        const applyTemporaryStyling = () => {
          dom.setStyles(this._trigger._domNode, {
            display: 'block',
            position: 'fixed',
            padding: '15px',
            fontSize: '30px',
            color: '#ffffff',
            backgroundColor: '#104070',
            borderRadius: '30px',
            textAlign: 'center',
            cursor: 'pointer',
            zIndex: 1000
          });
          Array.prototype.forEach.call(this._trigger._domNode.querySelectorAll('.fa'), (iconElement) => {
            dom.setStyles(iconElement, {
              minWidth: '30px',
              minHeight: '30px'
            });
          });
          dom.setStyles(this._popupContainerDomNode(), {
            position: 'relative',
            height: '100%',
            width: '100%',
            zIndex: 500
          });
        };
        dom.runOnDocumentReady(() => {
          setTimeout(() => {
            this._iframe = createIFrame(this.model.type);
            elementsInjection.inject(this._iframe);
            populateIFrame(this._iframe, this._css, html());
            configureIFrame(this._iframe, this.model);
            this._iframe.contentWindow.hellobar = hellobar;
            addCdnResources(this._iframe.contentDocument);
            this._trigger = new Trigger(this._iframe, this.model);
            this._popup = new Popup(this._iframe, this.model);
            this._audio = new Audio(this._iframe, this.model);
            this._trigger.setClickListener(onTriggerClicked);
            // TODO remove this line, use CSS instead
            applyTemporaryStyling();
            this.adjustSize();
            bindEvents();
            elementsIntents.applyViewCondition(this.model.view_condition, () => {
              this.show();
              this.notify();
            }, () => {
              this.show();
            });
            this.onInit && this.onInit();
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

      showPopup() {
        this._trigger.showCloseIcon();
        dom.showElement(this._popupContainerDomNode(), 'block');
        this.adjustSize();
        this.onShowPopup && this.onShowPopup();
      }

      hidePopup() {
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
        if (preview.isActive()) {
          // No notification for preview mode
          return;
        }
        this._audio.play();
        this._trigger.animate();
      }


      remove() {
        const unbindEvents = () => {
          const ctaElement = this._iframe.contentDocument.querySelector('.js-cta');
          ctaElement && ctaElement.removeEventListener('click', this._onCtaClicked);
        };
        unbindEvents();
        this._trigger && this._trigger.remove();
        this._popup && this._popup.remove();
        this._iframe && this._iframe.remove();
        this.onRemove && this.onRemove();
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
