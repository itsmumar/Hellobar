//= require modules/elements/elements.collecting

describe('Module elements.collecting', function () {

  function createDependencies(previewIsActive) {
    var dependencies = {
      'base.preview': jasmine.createSpyObj('base.preview', ['isActive']),
      'base.format': jasmine.createSpyObj('base.format', ['asBool']),
      'base.dom': jasmine.createSpyObj('base.dom', ['addClass', 'hideElement', 'shake']),
      'base.site': jasmine.createSpyObj('base.site', ['siteId']),
      'base.sanitizing': {
        sanitize: function (obj) {
          return obj;
        }
      },
      'base.bus': jasmine.createSpyObj('base.bus', ['trigger']),
      'tracking.internal': jasmine.createSpyObj('tracking.internal', ['send']),
      'elements.conversion': jasmine.createSpyObj('elements.conversion', ['converted'])
    };

    dependencies['base.preview'].isActive.and.returnValue(previewIsActive);
    dependencies['base.format'].asBool.and.returnValue(true);
    dependencies['base.site'].siteId.and.returnValue(12345);

    return dependencies;
  }

  function fakeSiteElement() {
    return {
      id: 23456
    };
  }

  it('supports email field creation', function () {
    var dependencies = createDependencies(false);
    var module = hellobar('elements.collecting', {
      dependencies: dependencies
    });
    var html = module.createInputFieldHtml({
      type: 'builtin-email'
    }, fakeSiteElement());
    expect(typeof html).toEqual('string');
    expect(html.indexOf('<input')).toBeGreaterThan(0);
    expect(html.indexOf('f-builtin-email')).toBeGreaterThan(0);
    expect(html.indexOf('hb-editable-block-input')).toBeGreaterThan(0);
  });

  it('supports custom field creation', function () {
    var dependencies = createDependencies(false);
    var module = hellobar('elements.collecting', {
      dependencies: dependencies
    });
    var html = module.createInputFieldHtml({
      id: 'custom',
      type: 'text',
      label: 'Custom Field'
    }, fakeSiteElement());
    expect(typeof html).toEqual('string');
    expect(html.indexOf('<input')).toBeGreaterThan(0);
    expect(html.indexOf('f-custom')).toBeGreaterThan(0);
    expect(html.indexOf('hb-editable-block-input')).toBeGreaterThan(0);
    expect(html.indexOf('Custom Field')).toBeGreaterThan(0);
  });


});
