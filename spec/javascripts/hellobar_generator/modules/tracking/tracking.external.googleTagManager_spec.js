//= require modules/tracking/tracking.external.googleTagManager

describe('Module tracking.external.googleTagManager', function () {
  var module;

  var externalTracking = {
    id: 5,
    type: 'view',
    category: 'HelloBar',
    action: 'View',
    label: 'SiteElement-5'
  };

  var eventName = 'HelloBarEvent';

  var event = {
    event: eventName,
    category: externalTracking.category,
    action: externalTracking.action,
    label: externalTracking.label
  };

  var utmCodes = {
    utm_source: 'HelloBar',
    utm_medium: 'test_site',
    utm_campaign: 'test'
  };

  var utmEvent = {
    event: eventName,
    category: externalTracking.category,
    action: externalTracking.action,
    label: externalTracking.label,
    utm_source: utmCodes.utm_source,
    utm_medium: utmCodes.utm_medium,
    utm_campaign: utmCodes.utm_campaign
  };

  var gtmSpy = jasmine.createSpyObj('gtmSpy', ['push']);
  var environment = jasmine.createSpyObj('base.environment', ['utmCodes']);

  function dependencies () {
    var dependencies = {
      'base.environment': environment
    }

    dependencies['base.environment'].utmCodes.and.returnValue({});

    return dependencies;
  };

  function dependenciesWithUtmCodes () {
    var dependencies = {
      'base.environment': environment
    }

    dependencies['base.environment'].utmCodes.and.returnValue(utmCodes);

    return dependencies;
  };

  beforeEach(function () {
    hellobar.finalize();
  });

  it('is available', function () {
    module = hellobar('tracking.external.googleTagManager', {
      dependencies: dependencies(),
      configurator: function (configuration) {
        configuration.provider(function () {
          return gtmSpy;
        });
      }
    });

    expect(module.available()).toEqual(true);
  });

  it('pushes event to Google Tag Manager without UTM codes if no codes are present', function () {
    module = hellobar('tracking.external.googleTagManager', {
      dependencies: dependencies(),
      configurator: function (configuration) {
        configuration.provider(function () {
          return gtmSpy;
        });
      }
    });

    module.send(externalTracking);

    expect(gtmSpy.push).toHaveBeenCalledWith(event);
  });

  it('pushes event to Google Tag Manager with UTM codes', function () {
    module = hellobar('tracking.external.googleTagManager', {
      dependencies: dependenciesWithUtmCodes(),
      configurator: function (configuration) {
        configuration.provider(function () {
          return gtmSpy;
        });
      }
    });

    module.send(externalTracking);

    expect(gtmSpy.push).toHaveBeenCalledWith(utmEvent);
  });
});
