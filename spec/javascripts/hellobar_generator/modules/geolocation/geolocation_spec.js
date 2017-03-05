//= require modules/core
//= require modules/geolocation/geolocation

// TODO this suite is disabled so far (geolocation testing doesn't work because of HB reference inside module)
xdescribe('Module geolocation', function () {

  afterEach(function() {
    hellobar.finalize();
  });

  function dependencies() {
    var storedValue = '{"value":"cityName:Moscow","expiration":"2057-11-09T20:47:15.337Z"}';
    var dependencies = {
      'base.storage': jasmine.createSpyObj('base.storage', ['getValue', 'setValue']),
      'base.ajax': jasmine.createSpyObj('base.ajax', ['get']),
      'base.site': jasmine.createSpyObj('base.site', ['siteId', 'siteUrl'])
    };
    dependencies['base.storage'].getValue.and.returnValue(storedValue);
    dependencies['base.site'].siteId.and.returnValue(123);
    dependencies['base.site'].siteUrl.and.returnValue('http://example-site.com');
    return dependencies;
  }

  it('returns city name', function () {
    var module = hellobar('geolocation', {
      dependencies: dependencies()
    });
    expect(module.cityName()).toEqual('Moscow');
  });

});
