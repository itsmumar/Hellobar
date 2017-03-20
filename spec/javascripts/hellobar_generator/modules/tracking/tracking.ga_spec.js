//= require modules/core
//= require modules/tracking/tracking.ga

describe('Module tracking.ga', function () {
  var module;
  var gaSpy;

  function simulateClick(element) {
    var ev = document.createEvent('Events');
    ev.initEvent('click', true, false);
    element.dispatchEvent(ev);
  }

  beforeEach(function () {
    var externalEvent = {
      id: 73454,
      site_element_id: 2,
      provider: 'google_analytics',
      type: 'test_type',
      category: 'Conversions',
      action: 'email_submission',
      label: 'Email conversion from HelloBar',
      value: null
    };
    gaSpy = jasmine.createSpy('gaSpy');
    module = hellobar('tracking.ga', {
      dependencies: {},
      configurator: function (configuration) {
        configuration.externalEvents([externalEvent]).gaProvider(function() {
          return gaSpy;
        });
      }
    });
  });

  it('sends GA event on explicit module call', function () {
    module.sendCtaClick('test_type');
    expect(gaSpy).toHaveBeenCalledWith('send', jasmine.any(Object));
  });

  it('sends GA event with DOM element tracking', function () {
    document.body.innerHTML = '<div><a href="#" class="js-cta"></a></div>';
    var ctaElement = document.querySelector('.js-cta');
    var controlObject = module.trackCtaClick(ctaElement, 'test_type');
    simulateClick(ctaElement);
    controlObject.stopTracking();
    simulateClick(ctaElement);

    expect(gaSpy).toHaveBeenCalledWith('send', jasmine.any(Object));
    expect(gaSpy.calls.count()).toEqual(1);
  });

  it('frees handlers during finalization', function () {
    document.body.innerHTML = '<div><a href="#" class="js-cta"></a></div>';
    var ctaElement = document.querySelector('.js-cta');
    module.trackCtaClick(ctaElement, 'test_type');
    simulateClick(ctaElement);
    module.finalize();
    simulateClick(ctaElement);

    expect(gaSpy).toHaveBeenCalledWith('send', jasmine.any(Object));
    expect(gaSpy.calls.count()).toEqual(1);
  });

});
