hellobar.defineModule('autofills', ['base.storage', 'base.dom'], function (storage, dom) {

  var subscriptions = [];

  /**
   * Wrapper class that encapsulates saving/restoring logic for autofills.
   * It's based on base.storage module.
   * @constructor
   */
  function AutofillStorage() {
    var expirationDays = 30;

    function autofillToKey(autofill) {
      return 'HB-autofill-' + autofill.id;
    }

    this.save = function (autofill, value) {
      storage.setValue(autofillToKey(autofill), value, expirationDays);
    };

    this.restore = function (autofill) {
      return storage.getValue(autofillToKey(autofill));
    };

  }

  var autofillStorage = new AutofillStorage();

  function getElements(doc, selector) {
    return doc.querySelectorAll(selector) || [];
  }

  function forAllAutofills(callback) {
    var autofills = configuration.autofills() || [];
    autofills.forEach(function (autofill) {
      callback && callback(autofill);
    });
  }

  function isElementAlreadyTracked(element) {
    return subscriptions.filter(function (subscription) {
        return subscription.element === element;
      }).length > 0;
  }

  function initializeValueCollection() {
    function initializeValueCollectionForDocument(doc) {
      forAllAutofills(function (autofill) {
        var elementsToTrack = getElements(doc, autofill.listen_selector);
        Array.prototype.forEach.call(elementsToTrack, function (elementToTrack) {
          if (isElementAlreadyTracked(elementToTrack)) {
            // Avoid redundant tracking
            return;
          }
          var blurHandler = function (evt) {
            if (evt && evt.target) {
              var value = evt.target.value;
              autofillStorage.save(autofill, value);
            }
          };
          var eventType = 'blur';
          elementToTrack.addEventListener(eventType, blurHandler);
          subscriptions.push({
            event: eventType,
            handler: blurHandler,
            element: elementToTrack
          });
        });
      });
    }

    dom.forAllDocuments(function (doc) {
      initializeValueCollectionForDocument(doc);
    });
  }

  function finalizeValueCollection() {
    subscriptions.forEach(function (subscription) {
      subscription.element.removeEventListener(subscription.event, subscription.handler);
    });
    subscriptions = [];
  }

  function populateValues() {
    forAllAutofills(function (autofill) {
      var value = autofillStorage.restore(autofill);
      value && dom.forAllDocuments(function (doc) {
        var elements = getElements(doc, autofill.populate_selector);
        Array.prototype.forEach.call(elements, function (element) {
          element.value = value;
        });
      });
    });
  }

  function run() {
    populateValues();
    initializeValueCollection();
  }

  /**
   * @class ModuleConfiguration
   * Encapsulates current module's configuration.
   */
  function ModuleConfiguration() {
    var _autofills = [];
    var _autoRun = false;
    this.autofills = function (autofills) {
      return autofills ? (_autofills = autofills) && this : _autofills;
    };
    this.autoRun = function (autoRun) {
      if (typeof autoRun === 'boolean') {
        _autoRun = autoRun;
        return this;
      } else {
        return _autoRun;
      }
    };
  }

  var configuration = new ModuleConfiguration();

  /**
   * @module autofills {object} Implements input autofilling logic in DOM.
   */
  return {
    configuration: function () {
      return configuration;
    },

    initialize: function (configurator) {
      configurator && configurator(configuration);

      configuration.autoRun() && dom.runOnDocumentReady(function () {
        run();
      });
    },

    run: function () {
      run();
    },

    finalize: function () {
      finalizeValueCollection();
    }
  };

});
