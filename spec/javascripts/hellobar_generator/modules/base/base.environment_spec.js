//= require modules/base/base.environment

describe('Module base.environment', function () {
  // TODO refactor base.environment module and then update this spec also
  var androidTablet = 'Mozilla/5.0 (Linux; Android 4.3; Nexus 7 Build/JSS15Q) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.76 Safari/537.36';
  var android = 'Mozilla/5.0 (Linux; Android 4.2.2; GT-I9505 Build/JDQ39) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.76 Mobile Safari/537.36';
  var chrome = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.103 Safari/537.36';
  var ipad = 'Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B137 Safari/601.1';
  var iphone = 'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1';

  var locationSearch = jasmine.createSpyObj('locationSearch', ['substr']);

  function getModule(userAgent, locationSearch) {
    return hellobar('base.environment', {
      dependencies: {},
      configurator: function (configuration) {
        configuration.userAgentProvider(function () {
          return userAgent;
        });

        configuration.locationSearchProvider(function () {
          return locationSearch;
        });
      }
    });
  }

  beforeEach(function () {
    hellobar.finalize();
  });

  it('detects ipad correctly', function () {
    var module = getModule(ipad, locationSearch);

    expect(module.device()).toEqual('tablet');
    expect(module.isMobileSafari()).toEqual(true);
  });

  describe('#getUtmCodes', function () {
    it('returns empty object if there are no UTM codes', function () {
      locationSearch.substr.and.returnValue('');

      var module = getModule(chrome, locationSearch);

      expect(module.utmCodes()).toEqual({});
    });

    it('returns an object with UTM codes if UTM codes are present in search', function () {
      var utmCodes = {
        utm_source: 'HelloBar',
        utm_medium: 'test_site',
        utm_campaign: 'test'
      };

      var search = 'utm_source=' + utmCodes.utm_source +
        '&utm_medium=' + utmCodes.utm_medium +
        '&utm_campaign=' + utmCodes.utm_campaign;

      locationSearch.substr.and.returnValue(search);

      var module = getModule(chrome, locationSearch);

      expect(module.utmCodes()).toEqual(utmCodes);
    });
  });
});
