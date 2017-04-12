//= require modules/core
//= require modules/tracking/tracking.external.googleAnalytics

describe('Module tracking.external.googleAnalytics', function () {
  var module;
  var gaSpy;

  beforeEach(function () {
    hellobar.finalize();
    gaSpy = jasmine.createSpy('gaSpy');
    module = hellobar('tracking.external.googleAnalytics', {
      dependencies: {},
      configurator: function (configuration) {
        configuration.gaProvider(function () {
          return gaSpy;
        });
      }
    });
  });

  it('sends GA event', function () {
    module.send('view');
    expect(gaSpy).toHaveBeenCalledWith('send', jasmine.any(Object));
  });

  it('is available if gaProvider is specified', function () {
    expect(module.introspect().available()).toEqual(true);
  });

});
