//= require modules/elements/elements

describe('Module elements', function () {
  var module;

  beforeEach(function () {
    hellobar.finalize();
    var ElementClass = function (model) {
      this.id = model.id;
      this.remove = this.attach = this.setCSS = function () {
      };
    };
    module = hellobar('elements', {
      configurator: function (configuration) {
        configuration.autoRun(false);
      },
      dependencies: {
        'base.preview': true,
        'base.sanitizing': {
          sanitize: function (arg) {
            return arg;
          }
        },
        'elements.rules': true,
        'elements.class': ElementClass,
        'elements.class.bar': ElementClass,
        'elements.class.slider': ElementClass,
        'elements.class.alert': ElementClass
      }
    });
  });

  it('successfully creates and removes elements', function () {
    var siteElementModel = {
      id: 123456,
      headline: 'Test'
    };
    module.createAndAddToPage(siteElementModel);
    expect(module.inspect().elementsOnPage().length).toEqual(1);

    expect(typeof module.findById(123456)).toEqual('object');
    expect(module.findById(123456).id).toEqual(123456);

    module.removeAllSiteElements();
    expect(module.inspect().elementsOnPage().length).toEqual(0);
  });

});
