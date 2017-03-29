hellobar.defineModule('base.site', ['hellobar'], function (hellobar) {

  var configuration = hellobar.createModuleConfiguration({
    siteId: 'number',
    siteUrl: 'string',
    secret: 'string'
  });

  /**
   * @module base.site {object} This module is for general site-scope operations.
   */
  return {
    configuration: function () {
      return configuration;
    },
    siteId: function () {
      return configuration.siteId();
    },
    siteUrl: function () {
      return configuration.siteUrl();
    },
    secret: function() {
      return configuration.secret();
    }
  };

});
