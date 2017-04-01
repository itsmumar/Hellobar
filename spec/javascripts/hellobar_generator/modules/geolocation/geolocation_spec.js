//= require modules/core
//= require modules/geolocation/geolocation

describe('Module geolocation', function () {

  afterEach(function () {
    hellobar.finalize();
  });

  function dependencies() {
    var storedValue = '{"value":"cityName:Moscow|countryName:Russia|regionName:Moscow","expiration":"2057-11-09T20:47:15.337Z"}';
    var dependencies = {
      'base.storage': jasmine.createSpyObj('base.storage', ['getValue', 'setValue']),
      'base.ajax': jasmine.createSpyObj('base.ajax', ['get']),
      'base.site': jasmine.createSpyObj('base.site', ['siteId', 'siteUrl']),
      'base.serialization': jasmine.createSpyObj('base.serialization', ['serialize', 'deserialize']),
      'base.deferred': hellobar('base.deferred')
    };
    dependencies['base.storage'].getValue.and.returnValue(storedValue);
    dependencies['base.site'].siteId.and.returnValue(123);
    dependencies['base.site'].siteUrl.and.returnValue('http://example-site.com');
    dependencies['base.serialization'].deserialize.and.returnValue({
      cityName: 'Moscow',
      countryName: 'Russia',
      regionName: 'Central'
    });
    return dependencies;
  }

  it('returns city name', function (done) {
    var module = hellobar('geolocation', {
      dependencies: dependencies()
    });
    module.cityName().then(function (cityName) {
      expect(cityName).toEqual('Moscow');
      done();
    });

  });

  it('returns country name', function (done) {
    var module = hellobar('geolocation', {
      dependencies: dependencies()
    });
    module.countryName().then(function (countryName) {
      expect(countryName).toEqual('Russia');
      done();
    });
  });

  it('returns region name', function (done) {
    var module = hellobar('geolocation', {
      dependencies: dependencies()
    });
    module.regionName().then(function (regionName) {
      expect(regionName).toEqual('Central');
      done();
    });

  });

  it('returns all geolocation data', function (done) {
    var module = hellobar('geolocation', {
      dependencies: dependencies()
    });
    module.getGeolocationData().then(function (data) {
      expect(data.cityName).toEqual('Moscow');
      expect(data.countryName).toEqual('Russia');
      done();
    });
  });

});
