//= require modules/tracking/tracking.external

describe('Module tracking.external', function () {
  var module;
  var externalTrackings;
  var googleAnalyticsMock;

  beforeEach(function () {
    hellobar.finalize();

    // FIXME
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

    googleAnalyticsMock.inspect = function () {
      return {
        available: function () {
          return true;
        }
      };
    };

    module = hellobar('tracking.external', {
      dependencies: {
        'tracking.external.googleAnalytics': googleAnalyticsMock
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
    module.send('view', 2);
    module.send('traffic_conversion', 2);

    expect(googleAnalyticsMock.send).toHaveBeenCalled();
    expect(googleAnalyticsMock.send.calls.count()).toEqual(2);
  });

  it('does not send anything for unknown tracking type', function () {
    module.send('unknown_tracking_type', 2);

    expect(googleAnalyticsMock.send).not.toHaveBeenCalled();
  });

  it('considers site_element_id while sending', function () {
    module.send('view', 12345);
    module.send('traffic_conversion', 54321);

    expect(googleAnalyticsMock.send).not.toHaveBeenCalled();
  });

  it('is considered available if at least one of the tracking engine is available', function () {
    expect(module.inspect().available()).toEqual(true);
  });
});
