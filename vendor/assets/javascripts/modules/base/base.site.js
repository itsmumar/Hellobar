hellobar.defineModule('base.site', [], function () {

  function ModuleConfiguration() {
    var _siteId;
    var _siteUrl;

    this.siteId = function (siteId) {
      return siteId ? (_siteId = siteId) && this : _siteId;
    };
    this.siteUrl = function (siteUrl) {
      return siteUrl ? (_siteUrl = siteUrl) && this : _siteUrl;
    };
  }

  var configuration = new ModuleConfiguration();

  return {
    configuration: function () {
      return configuration;
    },
    siteId: function () {
      return configuration.siteId();
    },
    siteUrl: function () {
      return configuration.siteUrl();
    }
  };

});
