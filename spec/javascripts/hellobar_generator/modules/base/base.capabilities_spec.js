//= require modules/base/base.capabilities

describe('Module base.capabilities', function () {
  var module;

  beforeEach(function () {
    hellobar.finalize();
    module = hellobar('base.capabilities', {
      dependencies: {},
      configurator: function (configuration) {
        configuration.capabilities({
          'allowed_capability': true,
          'denied_capability': false
        });
      }
    });
  });

  it('handles allowed capabilities correctly', function() {
    expect(module.has('allowed_capability')).toBeTruthy();
  });

  it('handles denied capabilities correctly', function() {
    expect(module.has('denied_capability')).toBeFalsy();
  });

  it('handles capabilities that are not specified explicitly', function() {
    expect(module.has('not_specified_capability')).toBeFalsy();
  });

});
