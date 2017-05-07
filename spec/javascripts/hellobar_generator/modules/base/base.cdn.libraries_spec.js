//= require modules/base/base.cdn.libraries

describe('Module base.cdn.libraries', function () {
  var module;
  var dependencies;

  function createDependencies() {
    var dependencies = {
      'base.cdn': jasmine.createSpyObj('base.cdn', ['addCss', 'addJs'])
    };
    return dependencies;
  }

  beforeEach(function () {
    hellobar.finalize();
    dependencies = createDependencies();
    module = hellobar('base.cdn.libraries', {
      dependencies: dependencies
    });
  });

  it('supports Font Awesome', function () {
    module.useFontAwesome();
    expect(dependencies['base.cdn'].addCss).toHaveBeenCalled();
    expect(dependencies['base.cdn'].addCss.calls.count()).toEqual(1);
  });

  it('supports Froala editor', function () {
    module.useFroala();
    expect(dependencies['base.cdn'].addCss).toHaveBeenCalled();
    // 5 files should be added (1 is font awesome dependency, 4 are Froala itself)
    expect(dependencies['base.cdn'].addCss.calls.count()).toEqual(5);
    expect(dependencies['base.cdn'].addJs.calls.count()).toEqual(0);
  });

});
