//= require modules/core
//= require modules/base/base.coloring

describe('Module base.coloring', function () {
  var module;

  beforeEach(function () {
    hellobar.finalize();
    module = hellobar('base.coloring', {
      dependencies: {}
    });
  });

  it('recognizes light colors', function() {
    expect(module.colorIsBright('#babaff')).toBeTruthy();
  });

  it('recognizes dark colors', function() {
    expect(module.colorIsBright('#303030')).toBeFalsy();
  });

});
