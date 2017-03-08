hellobar.defineModule('base.capabilities', [], function () {

  function ModuleConfiguration() {
    var _capabilities;
    this.capabilities = function (capabilities) {
      return capabilities ? (_capabilities = capabilities) : _capabilities;
    };
  }

  var configuration = new ModuleConfiguration();

  /**
   * @module {object} Provides information about capabilities of the HelloBar application.
   */
  return {
    configuration: function () {
      return configuration;
    },

    /**
     * Checks if application has given capability.
     * @param capability {string}
     * @returns {boolean}
     */
    has: function (capability) {
      var capabilities = configuration.capabilities();
      if (capabilities) {
        return !!capabilities[capability];
      } else {
        console.warn('Capabilities not defined');
      }
    }
  };
});
