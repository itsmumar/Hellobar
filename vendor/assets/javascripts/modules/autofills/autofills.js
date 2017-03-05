hellobar.defineModule('autofills', ['base.storage'], function (storage) {

  // TODO reuse forAllDocuments and runOnDocumentReady from base.dom module

  var subscriptions = [];

  function AutofillStorage() {
    var expirationDays = 30;

    function autofillToKey(autofill) {
      return 'HB-autofill-' + autofill.id;
    }

    this.save = function (autofill, value) {
      storage.setValue(autofillToKey(autofill), value, expirationDays);
    };

    this.restore = function (autofill) {
      storage.getValue(autofillToKey(autofill));
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

  function forAllDocuments(callback) {
    if (callback) {
      callback(document);
      var iframes = document.getElementsByTagName('iframe') || [];
      Array.prototype.forEach.call(iframes, function (iframe) {
        callback(iframe.contentDocument);
      });
    }
  }

  function initializeValueCollection() {
    function initializeValueCollectionForDocument(doc) {
      forAllAutofills(function (autofill) {
        var elementsToTrack = getElements(doc, autofill.listen_selector);
        Array.prototype.forEach.call(elementsToTrack, function (elementToTrack) {
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

    forAllDocuments(function (doc) {
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
      value && forAllDocuments(function (doc) {
        var elements = getElements(doc, autofill.populate_selector);
        Array.prototype.forEach.call(elements, function (element) {
          element.value = value;
        });
      });
    });
  }

  /**
   * @class ModuleConfiguration
   * Encapsulates current module's configuration.
   */
  function ModuleConfiguration() {
    var _autofills = [];
    this.autofills = function (autofills) {
      return autofills ? (_autofills = autofills) : _autofills;
    }
  }

  var configuration = new ModuleConfiguration();

  // Return module object
  return {
    configuration: function () {
      return configuration;
    },

    initialize: function () {
      function doLoad() {
        populateValues();
        initializeValueCollection();
      }

      document.body ? setTimeout(doLoad, 0) : document.addEventListener('DOMContentLoaded', function (evt) {
        doLoad();
      });
    },

    finalize: function () {
      finalizeValueCollection();
    }
  };

});
