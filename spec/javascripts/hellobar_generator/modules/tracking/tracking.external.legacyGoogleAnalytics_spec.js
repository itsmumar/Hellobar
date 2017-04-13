//= require modules/core
//= require modules/tracking/tracking.external.legacyGoogleAnalytics

describe('Module tracking.external.legacyGoogleAnalytics', function () {
  var module;
  var lgaSpy;

  beforeEach(function () {
    hellobar.finalize();

    lgaSpy = jasmine.createSpyObj('lgaSpy', ['push']);
    lgaSpy['I'] = {};

    module = hellobar('tracking.external.legacyGoogleAnalytics', {
      dependencies: {},
      configurator: function (configuration) {
        configuration.gaProvider(function () {
          return lgaSpy;
        });
      }
    });
  });

  it('sends legacy GA event', function () {
    var event = {category: 'Category', action: 'Action', label: 'Label'};

    module.send(event);
    expect(lgaSpy.push).toHaveBeenCalledWith(['_trackEvent', event.category, event.action, event.label]);
  });

  it('is available if gaProvider is specified', function () {
    expect(module.introspect().available()).toEqual(true);
  });
});
