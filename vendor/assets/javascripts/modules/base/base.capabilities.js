hellobar.defineModule('base.capabilities', ['hellobar'], function (hellobar) {

  var configuration = hellobar.createModuleConfiguration({
    capabilities: Array
  });

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
