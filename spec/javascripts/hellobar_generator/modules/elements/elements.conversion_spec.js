//= require modules/elements/elements.conversion

describe('Module elements.conversion', function () {
  var module;
  var dependencies;

  function createDependencies() {
    var dependencies = {
      'base.format': {
        normalizeUrl: function (url) {
          return url;
        }
      },
      'base.serialization': jasmine.createSpyObj('base.serialization', ['serialize', 'deserialize']),
      'base.bus': jasmine.createSpyObj('base.bus', ['trigger']),
      'lib.crypto': jasmine.createSpyObj('lib.crypto', ['SHA1']),
      'visitor': jasmine.createSpyObj('visitor', ['setConverted', 'getData']),
      'elements.data': jasmine.createSpyObj('elements.data', ['getData', 'setData']),
      'elements.visibility': jasmine.createSpyObj('elements.visibility', ['setVisibilityControlCookie']),
      'tracking.internal': jasmine.createSpyObj('tracking.internal', ['send']),
      'tracking.external': jasmine.createSpyObj('tracking.external', ['send'])
    };

    return dependencies;
  }

  function fakeSiteElement() {
    return {
      id: 12345,
      type: 'Modal',
      subtype: 'email',
      settings: {
        url: 'http://example.com'
      }
    };
  }

  beforeEach(function () {
    hellobar.finalize();
    dependencies = createDependencies();
    module = hellobar('elements.conversion', {
      dependencies: dependencies
    });
  });

  it('performs converted call', function () {
    var siteElement = fakeSiteElement();
    var callbackSpy = jasmine.createSpy('callback');
    module.converted(siteElement, callbackSpy);
    expect(dependencies['visitor'].setConverted).toHaveBeenCalled();
    expect(dependencies['elements.visibility'].setVisibilityControlCookie).toHaveBeenCalledWith('success', siteElement);
    expect(dependencies['elements.data'].setData).toHaveBeenCalled();
    expect(dependencies['base.bus'].trigger).toHaveBeenCalledWith('hellobar.elements.converted', siteElement);
    expect(dependencies['tracking.internal'].send).toHaveBeenCalled();
    expect(dependencies['tracking.external'].send).toHaveBeenCalled();
    expect(callbackSpy).not.toHaveBeenCalled();
  });

  it('performs viewed call', function () {
    var siteElement = fakeSiteElement();
    var callbackSpy = jasmine.createSpy('callback');
    module.viewed(siteElement, callbackSpy);
    expect(dependencies['visitor'].setConverted).not.toHaveBeenCalled();
    expect(dependencies['elements.visibility'].setVisibilityControlCookie).not.toHaveBeenCalled();
    expect(dependencies['elements.data'].setData).toHaveBeenCalled();
    expect(dependencies['base.bus'].trigger).toHaveBeenCalledWith('hellobar.elements.viewed', siteElement);
    expect(dependencies['tracking.internal'].send).toHaveBeenCalled();
    expect(dependencies['tracking.external'].send).toHaveBeenCalled();
    expect(callbackSpy).not.toHaveBeenCalled();
  });

});
