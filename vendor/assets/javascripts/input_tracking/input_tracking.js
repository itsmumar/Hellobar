(function () {

  var subscriptions = [];

  /**
   * @class ValueStorage
   * Abstracts out the way of storing input values (currently localStorage is used).
   */
  function ValueStorage() {
    var expirationDays = 30;

    function fieldToKey(field) {
      return 'HB_input_' + field.site_id + '_' + field.id;
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

    this.save = function (field, value) {
      localStorage.setItem(fieldToKey(field), JSON.stringify({
        value: value,
        expirationTimestamp: expirationTimestamp()
      }));
    };
    this.restore = function (field) {
      var key = fieldToKey(field);
      var storedObjectAsString = localStorage.getItem(key);
      if (storedObjectAsString) {
        var storedObject = JSON.parse(storedObjectAsString);
        if (storedObject.expirationTimestamp > currentTimestamp()) {
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

  function forAllFields(callback) {
    var fields = configuration.fields() || [];
    fields.forEach(function (field) {
      callback && callback(field);
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
      forAllFields(function (field) {
        var elements = getElements(doc, field.listen_selector);
        if (elements && elements.length === 1) {
          var elementToTrack = elements[0];
          var blurHandler = function (evt) {
            if (evt && evt.target) {
              var value = evt.target.value;
              valueStorage.save(field, value);
            }
          };
          var eventType = 'blur';
          elementToTrack.addEventListener(eventType, blurHandler);
          subscriptions.push({
            event: eventType,
            handler: blurHandler,
            element: elementToTrack
          });
        } else if (elements && elements.length > 1) {
          console.warn('WARNING: Multiple elements detected for selector ' + field.listen_selector);
        }
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
    forAllFields(function (field) {
      var value = valueStorage.restore(field);
      value && forAllDocuments(function (doc) {
        var elements = getElements(doc, field.populate_selector);
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
    var _fields = [];
    this.fields = function (fields) {
      return fields ? (_fields = fields) : _fields;
    }
  }

  var configuration = new ModuleConfiguration();

  // Return module object
  return {
    configuration: function () {
      return configuration;
    },

    load: function () {
      function doLoad() {
        populateValues();
        initializeValueCollection();
      }

      document.body ? setTimeout(doLoad, 0) : document.addEventListener('DOMContentLoaded', function (evt) {
        doLoad();
      });
    },

    unload: function () {
      finalizeValueCollection();
    }
  };

})();
