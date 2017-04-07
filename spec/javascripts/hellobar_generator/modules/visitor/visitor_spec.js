//= require modules/core
//= require modules/visitor/visitor

describe('Module visitor', function () {
  var module;

  function dependencies() {
    var dependencies = {
      'base.format': {
        normalizeUrl: function (url) {
          return url;
        }
      },
      'base.timezone': jasmine.createSpyObj('base.timezone', ['nowInTimezone']),
      'base.environment': jasmine.createSpyObj('base.environment', ['device']),
      'base.storage': jasmine.createSpyObj('base.storage', ['getValue', 'setValue']),
      'base.serialization': jasmine.createSpyObj('base.serialization', ['serialize', 'deserialize']),
      'base.site': jasmine.createSpyObj('base.site', ['siteId']),
      'geolocation': jasmine.createSpyObj('geolocation', ['getGeolocationData'])
    };
    dependencies['base.serialization'].deserialize.and.returnValue({});
    dependencies['base.environment'].device.and.returnValue('computer');
    return dependencies;
  }

  beforeEach(function () {
    module = hellobar('visitor', {
      dependencies: dependencies()
    });
  });


  it('visitor module provides formatted visit date', function () {
    expect(module.getData('dt')).toMatch(/\d{4}-\d{2}-\d{2}/);
  });

  it('visitor module provides device', function () {
    expect(module.getData('dv')).toEqual('computer');
  });

  it('visitor module provides first and last visit timestamp', function () {
    expect(module.getData('fv')).toEqual(jasmine.any(Number));
    expect(module.getData('lv')).toEqual(jasmine.any(Number));
  });

  it('visitor module provides life of the visitor in number of days', function () {
    expect(module.getData('lf')).toEqual(jasmine.any(Number));
  });

  it('visitor module provides number of visitor visits and visitor sessions', function () {
    expect(module.getData('ns')).toEqual(jasmine.any(Number));
    expect(module.getData('nv')).toEqual(jasmine.any(Number));
  });

  it('visitor module provides page URL and path', function () {
    expect(module.getData('pu')).toEqual(jasmine.any(String));
    expect(module.getData('pup')).toEqual(jasmine.any(String));
  });

  it('visitor module provides all data as object', function () {
    expect(typeof module.getData()).toEqual('object');
  });

});

