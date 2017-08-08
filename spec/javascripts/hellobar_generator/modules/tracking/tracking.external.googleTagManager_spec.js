//= require modules/tracking/tracking.external.googleTagManager

describe('Module tracking.external.googleTagManager', function () {
  var module;
  var gtmSpy;

  var externalTracking = {
    id: 5,
    type: 'view',
    category: 'HelloBar',
    action: 'View',
    label: 'SiteElement-5'
  }

  var eventName = 'HelloBarEvent';

  var event = {
    event: eventName,
    category: externalTracking.category,
    action: externalTracking.action,
    label: externalTracking.label
  }

  var utmCodes = {
    utm_source: 'HelloBar',
    utm_medium: 'test_site',
    utm_campaign: 'test'
  }

  var utmEvent = {
    event: eventName,
    category: externalTracking.category,
    action: externalTracking.action,
    label: externalTracking.label,
    utm_source: utmCodes.utm_source,
    utm_medium: utmCodes.utm_medium,
    utm_campaign: utmCodes.utm_campaign
  }
  // var locationSpy = jasmine.createSpyObj(location, ['search']);

  beforeEach(function () {
    hellobar.finalize();

    gtmSpy = jasmine.createSpyObj('gtmSpy', ['push']);

    module = hellobar('tracking.external.googleTagManager', {
      dependencies: {},
      configurator: function (configuration) {
        configuration.provider(function () {
          return gtmSpy;
        });
      }
    });
  });

  it('is available', function () {
    expect(module.available()).toEqual(true);
  });

  it('pushes event to Google Tag Manager', function () {
    module.send(externalTracking);
    expect(gtmSpy.push).toHaveBeenCalledWith(event);
  });

  it('pushes event to Google Tag Manager with utm tags', function () {
    var utmCodesSpy = spyOn(module, 'utmCodes').and.returnValue(utmCodes);

    module.send(externalTracking);
    expect(utmCodesSpy).toHaveBeenCalled();
    expect(gtmSpy.push).toHaveBeenCalledWith(utmEvent);
  });
});
