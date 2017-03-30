//= require modules/core
//= require modules/geolocation/geolocation

describe('Module geolocation', function () {

  afterEach(function() {
    hellobar.finalize();
  });

  function dependencies() {
    var storedValue = '{"value":"cityName:Moscow|countryName:Russia|regionName:Moscow","expiration":"2057-11-09T20:47:15.337Z"}';
    var dependencies = {
      'base.storage': jasmine.createSpyObj('base.storage', ['getValue', 'setValue']),
      'base.ajax': jasmine.createSpyObj('base.ajax', ['get']),
      'base.site': jasmine.createSpyObj('base.site', ['siteId', 'siteUrl']),
      'base.serialization': jasmine.createSpyObj('base.serialization', ['serialize', 'deserialize'])
    };
    dependencies['base.storage'].getValue.and.returnValue(storedValue);
    dependencies['base.site'].siteId.and.returnValue(123);
    dependencies['base.site'].siteUrl.and.returnValue('http://example-site.com');
    dependencies['base.serialization'].deserialize.and.returnValue({cityName: 'Moscow', countryName: 'Russia', regionName: 'Central'});
    return dependencies;
  }

  // TODO fix tests, introduce promises

  it('returns city name', function () {
    var module = hellobar('geolocation', {
      dependencies: dependencies()
    });
    expect(module.cityName()).toEqual('Moscow');
  });

  it('returns country name', function () {
    var module = hellobar('geolocation', {
      dependencies: dependencies()
    });
    expect(module.countryName()).toEqual('Russia');
  });

  it('returns region name', function () {
    var module = hellobar('geolocation', {
      dependencies: dependencies()
    });
    expect(module.regionName()).toEqual('Central');
  });

  it('returns all geolocation data', function () {
    var module = hellobar('geolocation', {
      dependencies: dependencies()
    });
    var data = module.getGeolocationData();
    expect(data.cityName).toEqual('Moscow');
    expect(data.countryName).toEqual('Russia');
  });

});
