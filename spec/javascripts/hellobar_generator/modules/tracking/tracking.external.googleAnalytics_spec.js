//= require modules/tracking/tracking.external.googleAnalytics

describe('Module tracking.external.googleAnalytics', function () {
  var externalTracking = {
    id: 5,
    type: 'view',
    category: 'HelloBar',
    action: 'View',
    label: 'SiteElement-5'
  }

  describe('Google Analytics', function () {
    var gaSpy;
    var module;

    var event = {
      hitType: 'event',
      eventCategory: externalTracking.category,
      eventAction: externalTracking.action,
      eventLabel: externalTracking.label
    }

    beforeEach(function () {
      hellobar.finalize();

      gaSpy = jasmine.createSpy('gaSpy');

      module = hellobar('tracking.external.googleAnalytics', {
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

    it('sends event to Google Analytics', function () {
      module.send(externalTracking);
      expect(gaSpy).toHaveBeenCalledWith('send', event);
    });
  });
});
