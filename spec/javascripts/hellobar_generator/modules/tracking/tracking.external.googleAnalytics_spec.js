//= require modules/tracking/tracking.external.googleAnalytics

describe('Module tracking.external.googleAnalytics', function () {
  var externalTracking = {
    id: 5,
    type: 'view',
    category: 'HelloBar',
    action: 'View',
    label: 'SiteElement-5'
  }

  describe('Modern Google Analytics', function () {
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

    it('returns true for availableModern()', function () {
      expect(module.availableModern()).toEqual(true);
    });

    it('returns false for availableLegacy()', function () {
      expect(module.availableLegacy()).toEqual(false);
    });

    it('sends event to Google Analytics', function () {
      module.send(externalTracking);
      expect(gaSpy).toHaveBeenCalledWith('send', event);
    });
  });

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

    it('returns false for availableModern()', function () {
      expect(module.availableModern()).toEqual(false);
    });

    it('returns false for availableLegacy()', function () {
      expect(module.availableLegacy()).toEqual(true);
    });

    it('sends event to Legacy Google Analytics', function () {
      module.send(externalTracking);
      expect(gaSpy.push).toHaveBeenCalledWith(event);
    });
  });
});
