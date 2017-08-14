//= require modules/tracking/tracking.external.legacyGoogleAnalytics

describe('Module tracking.external.legacyGoogleAnalytics', function () {
  var externalTracking = {
    id: 5,
    type: 'view',
    category: 'HelloBar',
    action: 'View',
    label: 'SiteElement-5'
  }

  describe('Legacy Google Analytics', function () {
    var gaSpy;
    var module;

    var event = [
      '_trackEvent',
      externalTracking.category,
      externalTracking.action,
      externalTracking.label
    ]

    beforeEach(function () {
      hellobar.finalize();

      gaSpy = jasmine.createSpyObj('gaSpy', ['push']);

      module = hellobar('tracking.external.legacyGoogleAnalytics', {
        dependencies: {},
        configurator: function (configuration) {
          configuration.provider(function () {
            return gaSpy;
          });
        }
      });
    });

    it('is available', function () {
      expect(module.available()).toEqual(true);
    });

    it('sends event to Legacy Google Analytics', function () {
      module.send(externalTracking);
      expect(gaSpy.push).toHaveBeenCalledWith(event);
    });
  });
});
