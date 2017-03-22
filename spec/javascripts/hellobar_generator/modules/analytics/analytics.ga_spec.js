//= require modules/core
//= require modules/analytics/analytics.ga

describe('Module analytics.ga', function () {
  var module;
  var gaSpy;

  beforeEach(function () {
    hellobar.finalize();
    var analyticsEvents = [{
      site_element_id: 2,
      provider: 'google_analytics',
      type: 'view',
      category: 'HelloBar',
      action: 'View',
      label: 'Bar viewing from HelloBar'
    }, {
      site_element_id: 2,
      provider: 'google_analytics',
      type: 'traffic_conversion',
      category: 'HelloBar',
      action: 'Converted',
      label: 'Email conversion from HelloBar'
    }];
    gaSpy = jasmine.createSpy('gaSpy');
    module = hellobar('analytics.ga', {
      dependencies: {},
      configurator: function (configuration) {
        configuration.analyticsEvents(analyticsEvents).gaProvider(function() {
          return gaSpy;
        });
      }
    });
  });

  it('sends GA event with view type', function () {
    module.send('view');
    expect(gaSpy).toHaveBeenCalledWith('send', jasmine.any(Object));
  });

  it('sends GA event with conversion type', function () {
    module.send('traffic_conversion');
    expect(gaSpy).toHaveBeenCalledWith('send', jasmine.any(Object));
  });

  it('does not send GA event with unknown event type', function () {
    module.send('unknown');
    expect(gaSpy).not.toHaveBeenCalled();
  });

});
