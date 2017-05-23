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
    }

    return ContentUpgrade;
  });
