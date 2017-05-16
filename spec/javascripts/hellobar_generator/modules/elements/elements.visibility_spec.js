//= require modules/elements/elements.visibility

describe('Module elements.visibility', function () {
  var module;
  var dependencies;

  function fakeSiteElement() {
    return {
      id: 12345,
      settings: {
        cookie_settings: {
          duration: 10,
          success_duration: 20
        }
      }
    }
  }

  function createDependencies() {
    var dependencies = {
      'base.storage': jasmine.createSpyObj('base.storage', ['getValue', 'setValue', 'removeValue']),
      'base.environment': jasmine.createSpyObj('base.environment', ['isMobileDevice', 'isMobileWidth']),
      'elements.data': jasmine.createSpyObj('base.environment', ['getData'])
    };

    dependencies['base.environment'].isMobileDevice.and.returnValue(false);
    dependencies['base.environment'].isMobileWidth.and.returnValue(false);
    dependencies['elements.data'].getData.and.returnValue(10000);

    return dependencies;
  }


  beforeEach(function () {
    localStorage.clear();
    hellobar.finalize();
    dependencies = createDependencies();
    module = hellobar('elements.visibility', {
      dependencies: dependencies
    });
  });

  it('successfully sets visibility control cookie', function () {
    module.setVisibilityControlCookie('dismiss', fakeSiteElement());
    expect(dependencies['base.storage'].setValue).toHaveBeenCalledWith(jasmine.any(String), jasmine.any(String), jasmine.any(Number));
  });

  it('does not set visibility control cookie if day count settings are not specified', function () {
    module.setVisibilityControlCookie('dismiss', { id: 12345 });
    expect(dependencies['base.storage'].setValue).not.toHaveBeenCalled();
  });

  it('supports cookie expiring', function () {
    var siteElement = fakeSiteElement();

    module.setVisibilityControlCookie('success', siteElement);
    expect(dependencies['base.storage'].setValue).toHaveBeenCalled();

    module.removeVisibilityControlCookie('success', siteElement.id);
    expect(dependencies['base.storage'].removeValue).toHaveBeenCalled();
  });

});
