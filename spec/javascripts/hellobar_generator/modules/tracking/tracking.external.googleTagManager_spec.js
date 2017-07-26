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
  var event = {
    event: 'HelloBarEvent',
    category: externalTracking.category,
    action: externalTracking.action,
    label: externalTracking.label
  }

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

  it('pushes event to Google Tag Manager', function () {
    module.send(externalTracking);
    expect(gtmSpy.push).toHaveBeenCalledWith(event);
  });

  it('is available if provider is specified', function () {
    expect(module.available()).toEqual(true);
  });
});
