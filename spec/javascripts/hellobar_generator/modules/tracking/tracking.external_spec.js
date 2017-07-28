//= require modules/tracking/tracking.external

describe('Module tracking.external', function () {
  var module;
  var externalTrackings;
  var googleAnalyticsMock;
  var googleTagManagerMock;
  var id = 2;

  beforeEach(function () {
    hellobar.finalize();

    externalTrackings = [{
      id: id,
      type: 'view',
      category: 'HelloBar',
      action: 'View',
      label: 'SiteElement-2'
    }, {
      id: id,
      type: 'traffic_conversion',
      category: 'HelloBar',
      action: 'Converted',
      label: 'SiteElement-2'
    }];

    googleAnalyticsMock = jasmine.createSpyObj('GA', ['send']);
    googleTagManagerMock = jasmine.createSpyObj('GTM', ['send']);

    googleAnalyticsMock.available = function () {
      return true;
    };

    googleTagManagerMock.available = function () {
      return true;
    };

    module = hellobar('tracking.external', {
      dependencies: {
        'tracking.external.googleAnalytics': googleAnalyticsMock,
        'tracking.external.googleTagManager': googleTagManagerMock
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
    module.send('view', id);
    module.send('traffic_conversion', id);

    expect(googleAnalyticsMock.send).toHaveBeenCalled();
    expect(googleAnalyticsMock.send.calls.count()).toEqual(2);

    expect(googleTagManagerMock.send).toHaveBeenCalled();
    expect(googleTagManagerMock.send.calls.count()).toEqual(2);
  });

  it('does not send anything for unknown tracking type', function () {
    module.send('unknown_tracking_type', id);

    expect(googleAnalyticsMock.send).not.toHaveBeenCalled();
    expect(googleTagManagerMock.send).not.toHaveBeenCalled();
  });

  it('considers id (SiteElement#id) while sending', function () {
    module.send('view', 12345);
    module.send('traffic_conversion', 54321);

    expect(googleAnalyticsMock.send).not.toHaveBeenCalled();
    expect(googleTagManagerMock.send).not.toHaveBeenCalled();
  });

  it('is considered available if at least one of the tracking engines is available', function () {
    expect(module.available()).toEqual(true);
  });
});
