//= require modules/core
//= require modules/base/base.site

describe('Module base.site', function () {

  var sampleSiteId = 12345;
  var sampleSiteUrl = 'http://example-site.com';

  var module;

  beforeEach(function () {
    module = hellobar('base.site', {
      configurator: function (configuration) {
        configuration.siteId(sampleSiteId).siteUrl(sampleSiteUrl);
      }
    });
  });

  it('provides siteId', function () {
    expect(module.siteId()).toEqual(sampleSiteId);
  });

  it('provides siteUrl', function () {
    expect(module.siteUrl()).toEqual(sampleSiteUrl);
  });

});
