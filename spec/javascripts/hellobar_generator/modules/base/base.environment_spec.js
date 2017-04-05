//= require modules/core
//= require modules/base/base.environment

describe('Module base.environment', function () {

  function getModule(userAgent) {
    return hellobar('base.environment', {
      dependencies: {},
      configurator: function (configuration) {
        configuration.userAgentProvider(function() {
          return userAgent;
        });
      }
    });
  }

  beforeEach(function () {
    hellobar.finalize();
  });

  it('detects ipad correctly', function() {
    var ipad = 'Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) ' +
      'Version/9.0 Mobile/13B137 Safari/601.1';
    var module = getModule(ipad);
    expect(module.device()).toEqual('tablet');
    expect(module.isMobileSafari()).toEqual(true);
  });

  // TODO refactor base.environment module and then update this spec also
  var iphone = 'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1';
  var androidTablet = 'Mozilla/5.0 (Linux; Android 4.3; Nexus 7 Build/JSS15Q) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.76 Safari/537.36';
  var android = 'Mozilla/5.0 (Linux; Android 4.2.2; GT-I9505 Build/JDQ39) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.76 Mobile Safari/537.36';
  var chrome = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.103 Safari/537.36';

});
