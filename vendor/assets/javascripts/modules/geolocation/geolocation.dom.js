hellobar.defineModule('geolocation.dom', ['base.dom', 'geolocation'], function (dom, geolocation) {

  var geolocationAttributeName = 'data-hb-geolocation';
  var geolocationDefaultAttributeName = 'data-hb-geolocation-default';
  var geolocationSelector = '[' + geolocationAttributeName + ']';

  function processPlaceholderElement(placeholder) {
    var defaultValue = function () {
      return placeholder.getAttribute(geolocationDefaultAttributeName) || '';
    };
    var dataKey = placeholder.getAttribute(geolocationAttributeName) + 'Name';
    geolocation.getGeolocationData(dataKey, function (value) {
      placeholder.textContent = (value || defaultValue());
    });
  }

  function ModuleConfiguration() {
    var _autoRun = false;
    this.autoRun = function (autoRun) {
      return typeof autoRun === 'boolean' ? (_autoRun = autoRun) : _autoRun;
    }
  }

  var configuration = new ModuleConfiguration();

  var module = {

    initialize: function (configurator) {
      configurator && configurator.call(module, configuration);
      if (configuration.autoRun()) {
        setTimeout(function () {
          module.processAllDocuments();
        }, 0);
      }
    },

    configuration: function () {
      return configuration;
    },

    /**
     * In the context of given element, it searches for spans with attribute data-hb-geolocation
     * and puts corresponding geolocation name there.
     * @param element {Element} DOM element to process
     */
    processElement: function (element) {
      var placeholders = element.querySelectorAll(geolocationSelector);
      Array.prototype.forEach.call(placeholders, function (placeholder) {
        processPlaceholderElement(placeholder);
      });
    },

    processAllDocuments: function () {
      dom.runOnDocumentReady(function () {
        dom.forAllDocuments(function (doc) {
          var placeholders = doc.querySelectorAll(geolocationSelector);
          Array.prototype.forEach.call(placeholders, function (placeholder) {
            processPlaceholderElement(placeholder);
          });
        });
      });

    }
  };

  return module;

});
