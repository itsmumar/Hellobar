function autofills() {

  var subscriptions = [];

  /**
   * @class ValueStorage
   * Abstracts out the way of storing input values (currently localStorage is used).
   */
  function ValueStorage() {
    var expirationDays = 30;

    function autofillToKey(autofill) {
      return 'HB-autofill-' + autofill.id;
    }

    function dateToTimestamp(date) {
      return date.toISOString();
    }

    function currentTimestamp() {
      return dateToTimestamp(new Date());
    }

    function expirationTimestamp() {
      var date = new Date();
      date.setDate(date.getDate() + expirationDays);
      return dateToTimestamp(date);
    }

    this.save = function (autofill, value) {
      localStorage.setItem(autofillToKey(autofill), JSON.stringify({
        value: value,
        expiration: expirationTimestamp()
      }));
    };
    this.restore = function (autofill) {
      var key = autofillToKey(autofill);
      var storedObjectAsString = localStorage.getItem(key);
      if (storedObjectAsString) {
        var storedObject = JSON.parse(storedObjectAsString);
        if (storedObject.expiration > currentTimestamp()) {
          return storedObject.value;
        } else {
          localStorage.removeItem(key);
        }
      }
      return undefined;
    };
  }

  var valueStorage = new ValueStorage();

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
        try {
          var iframeDocument = iframe.contentDocument;
          callback(iframeDocument);
        } catch (e) {
          // We're fully ignoring iframe cross-origin restriction exception (it's represented with DOMException)
          // and print warning for anything else
          if (!(e instanceof DOMException)) {
            console.warn(e);
          }
        }
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
              valueStorage.save(autofill, value);
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
      var value = valueStorage.restore(autofill);
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
    };

    this.hasAutofills = function () {
      return _autofills && _autofills.length > 0;
    };
  }

  var configuration = new ModuleConfiguration();

  // Return module object
  return {
    configuration: function () {
      return configuration;
    },

    load: function () {
      function doLoad() {
        if (configuration.hasAutofills()) {
          populateValues();
          initializeValueCollection();
        }
      }

      document.body ? setTimeout(doLoad, 0) : document.addEventListener('DOMContentLoaded', function (evt) {
        doLoad();
      });
    },

    unload: function () {
      finalizeValueCollection();
    }
  };

}
