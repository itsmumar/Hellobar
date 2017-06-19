hellobar.defineModule('contentUpgrades.class',
  [],
  function () {

    class ContentUpgrade {
      constructor(model) {
        this._model = model;
      }

      model() {
        return this._model;
      }

      contentDocument() {
        return document.getElementById('hb-cu-modal-' + this.model().id);
      }

      getSiteElementDomNode() {
        return this.contentDocument()
      }

      getMainContainer () {
        const node = this.getSiteElementDomNode();

        return node && node.querySelector('.hb-cu-main-content');
      }

      getThankYouContainer () {
        const node = this.getSiteElementDomNode();

        return node && node.querySelector('.hb-cu-thank-you');
      }

      showThankYou () {
        const mainContainer = this.getMainContainer();
        const thankYouContainer = this.getThankYouContainer();

        if (mainContainer && thankYouContainer) {
          mainContainer.style.display = 'none';
          thankYouContainer.style.display = 'block';
        }
      }
    }

    return ContentUpgrade;
  });
