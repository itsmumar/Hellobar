//= require modules/base/base.selfcheck

describe('Module base.selfcheck', function () {

  function getModule(previewIsActive, siteUrl) {
    function dependencies() {
      var dependencies = {
        'base.preview': jasmine.createSpyObj('base.preview', ['isActive']),
        'base.format': {
          normalizeUrl: function (url) {
            return url;
          }
        },
        'base.site': jasmine.createSpyObj('base.preview', ['siteUrl'])
      };
      dependencies['base.preview'].isActive.and.returnValue(previewIsActive);
      dependencies['base.site'].siteUrl.and.returnValue(siteUrl);
      return dependencies;
    }

    return hellobar('base.selfcheck', {
      dependencies: dependencies()
    });
  }

  beforeEach(function () {
    hellobar.finalize();
  });

  it('always passes checks in preview mode', function () {
    expect(getModule(true, 'http://example.com').scriptIsInstalledProperly()).toBeTruthy();
  });

  it('passes checks for localhost', function () {
    function isLocalhost() {
      return window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
    }

    expect(getModule(false, 'http://some-site.com').scriptIsInstalledProperly()).toEqual(isLocalhost());
  });

});
