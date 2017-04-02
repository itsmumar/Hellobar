hellobar.defineModule('geolocation.injection',
  ['hellobar', 'base.dom', 'base.bus', 'geolocation'],
  function (hellobar, dom, bus, geolocation) {

    var geolocationAttributeName = 'data-hb-geolocation';
    var geolocationDefaultAttributeName = 'data-hb-geolocation-default';
    var geolocationSelector = '[' + geolocationAttributeName + ']';

    function processPlaceholderElement(placeholder) {
      var defaultValue = function () {
        return placeholder.getAttribute(geolocationDefaultAttributeName) || '';
      };
      var dataKey = placeholder.getAttribute(geolocationAttributeName) + 'Name';
      geolocation.getGeolocationData(dataKey).then((value) => {
        placeholder.textContent = (value || defaultValue());
      });
    }

    var configuration = hellobar.createModuleConfiguration({
      autoRun: {
        type: 'boolean',
        defaultValue: false
      }
    });

    /**
     * @module {object} Performs geolocation data injection into DOM.
     * We can search through the DOM and find 'span' elements with marker attribute data-hb-geolocation -
     * those spans will be processed automatically, corresponding geolocation name will be retrieved
     * from 'geolocation' module and inserted in the span as text content.
     * Attribute data-hb-geolocation supports three values: 'city', 'region', 'country'.
     * Also data-hb-deolocation-default can be specified -
     * its value will be used if geolocation module fails to get the required exact geolocation name.
     */
    var module = {

      initialize: function (configurator) {
        configurator && configurator.call(module, configuration);
        if (configuration.autoRun()) {
          setTimeout(function () {
            module.processAllDocuments();
          }, 0);
          bus.on('hellobar.elements.viewed', () => {
            module.processAllDocuments();
          });
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
          !placeholder.textContent && processPlaceholderElement(placeholder);
        });
      },

      /**
       * In the context of all available DOM documents, it searches for spans with attribute data-hb-geolocation
       * and puts corresponding geolocation name there.
       */
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
