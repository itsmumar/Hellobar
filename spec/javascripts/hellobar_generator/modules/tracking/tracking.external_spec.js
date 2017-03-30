//= require modules/core
//= require modules/tracking/tracking.external

describe('Module tracking.external', function () {

  var module;
  var externalTrackings;
  var googleAnalyticsMock;
  var legacyGoogleAnalyticsMock;

  beforeEach(function () {
    hellobar.finalize();

    externalTrackings = [{
      site_element_id: 2,
      provider: 'google_analytics',
      type: 'view',
      category: 'HelloBar',
      action: 'View',
      label: 'SiteElement-2'
    }, {
      site_element_id: 2,
      provider: 'legacy_google_analytics',
      type: 'traffic_conversion',
      category: 'HelloBar',
      action: 'Converted',
      label: 'SiteElement-2'
    }];

    googleAnalyticsMock = jasmine.createSpyObj('GA', ['send']);
    legacyGoogleAnalyticsMock = jasmine.createSpyObj('LGA', ['send']);

    module = hellobar('tracking.external', {
      dependencies: {
        'tracking.external.googleAnalytics': googleAnalyticsMock,
        'tracking.external.legacyGoogleAnalytics': legacyGoogleAnalyticsMock
      },
      configurator: function (configuration) {
        configuration.externalTrackings(externalTrackings);
      }
    });
  });

  it('provides correct configuration', function () {
    expect(module.configuration()).toBeDefined();
    expect(module.configuration().externalTrackings()).toEqual(externalTrackings);
  });

  it('calls tracking engines on send', function () {
    module.send('view');
    module.send('traffic_conversion');

    expect(googleAnalyticsMock.send).toHaveBeenCalled();
    expect(googleAnalyticsMock.send.calls.count()).toEqual(2);

    expect(legacyGoogleAnalyticsMock.send).toHaveBeenCalled();
    expect(legacyGoogleAnalyticsMock.send.calls.count()).toEqual(2);
  });

  it('does not send anything for unknown tracking type', function () {
    module.send('unknown_tracking_type');

    expect(googleAnalyticsMock.send).not.toHaveBeenCalled();
    expect(legacyGoogleAnalyticsMock.send).not.toHaveBeenCalled();
  });
});
