//= require modules/core
//= require modules/base/base.templating

describe('Module base.templating', function () {

  function getModule(templates) {
    return hellobar('base.templating', {
      configurator: function (configuration) {
        for (var templateName in templates) {
          configuration.addTemplate(templateName, templates[templateName]);
        }
      },
      dependencies: {
        'base.preview': {
          isActive: function () {
            return false;
          }
        }
      }
    });
  }

  beforeEach(function () {
    hellobar.finalize();
  });

  it('registers templates with correct name', function () {
    var result = getModule({
      'test_name': 'template_content'
    }).getTemplateByName('test_name');
    expect(result).toEqual('template_content');
  });

  it('performs expansion in templates', function () {
    expect(getModule({}).renderTemplate('2+2={{2+2}}')).toEqual('2+2=4');
  });

  it('understands siteElement variable in template content', function () {
    expect(getModule({}).renderTemplate('Name={{siteElement.name}}', {name: 'John'})).toEqual('Name=John');
  });

  it('leaves template unparsed if it contains an error', function () {
    expect(getModule({}).renderTemplate('{{var}} {{for}}')).toEqual('var for');
  });

});
