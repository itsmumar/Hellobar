//= require modules/core
//= require modules/base/base.sanitizing

describe('Module base.sanitizing', function () {
  var module;

  beforeEach(function () {
    module = hellobar('base.sanitizing', {
      dependencies: {}
    });
  });

  it('escapes HTML tags', function () {
    expect(module.sanitize({
      test: '<script>'
    })).toEqual({
      test: '&lt;script&gt;'
    });
    expect(module.sanitize({
      test: '<style>.test{}</style>'
    })).toEqual({
      test: '&lt;style&gt;.test{}&lt;/style&gt;'
    });
  });

  it('escapes double quotes', function () {
    expect(module.sanitize({
      test: '<div class="test"></div>'
    })).toEqual({
      test: '&lt;div class=&quot;test&quot;&gt;&lt;/div&gt;'
    });
  });

  it('supports whitelist', function () {
    expect(module.sanitize({
      test: '<div class="test"></div>'
    }, ['test'])).toEqual({
      test: '<div class="test"></div>'
    });
  });

});
