//= require modules/core
//= require modules/base/base.metainfo

describe('Module base.metainfo', function () {
  var module;

  beforeEach(function () {
    hellobar.finalize();
    module = hellobar('base.metainfo', {
      dependencies: {},
      configurator: function (configuration) {
        configuration.version("9ca6c58b392a4cb879753e097667205a32e516ec");
        configuration.timestamp("2017-04-07 13:05:33 UTC");
      }
    });
  });

  it('has version method', function() {
    expect(module.version()).toEqual('9ca6c58b392a4cb879753e097667205a32e516ec');
  });

  it('has timestamp method', function() {
    expect(module.timestamp()).toEqual('2017-04-07 13:05:33 UTC');
  });

  it('has info method', function() {
    expect(module.info()).toEqual('version 9ca6c58b392a4cb879753e097667205a32e516ec was generated at 2017-04-07 13:05:33 UTC');
  });
});
