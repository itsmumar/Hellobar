//= require modules/base/base.deferred
//= require modules/rules/rules

describe('Module rules', function () {

  function dependencies() {
    var dependencies = {
      'base.deferred': hellobar('base.deferred'),
      'elements.visibility': jasmine.createSpyObj('elements.visibility', ['shouldShowElement']),
      'elements.relevance': jasmine.createSpyObj('elements.relevance', ['getBestElement']),
      'rules.resolving': jasmine.createSpyObj('rules.resolving', ['resolve'])
    };

    dependencies['elements.visibility'].shouldShowElement.and.returnValue(true);
    dependencies['elements.relevance'].getBestElement.and.callFake(elements => elements[0]);
    dependencies['rules.resolving'].resolve.and.callFake(rule => {
      return { rule: rule, ruleActive: true }
    });

    return dependencies;
  }

  function fakeSiteElement(siteElementId, elementType) {
    return {
      id: siteElementId,
      type: elementType || 'Modal',
      subtype: 'email'
    };
  }

  beforeEach(function () {
    hellobar.finalize();
  });

  it('supports rule without any conditions', function (done) {
    var module = hellobar('rules', {
      dependencies: dependencies(),
      configurator: function (configuration) {
        configuration.addRule('all', [], [fakeSiteElement(1, 'Bar'), fakeSiteElement(2, 'Slider')]);
      }
    });

    module.apply().then(function (siteElements) {
      expect(siteElements.length).toEqual(2);
      done();
    });
  });

  it('does not allow to show multiple elements with the same type', function (done) {
    var module = hellobar('rules', {
      dependencies: dependencies(),
      configurator: function (configuration) {
        configuration.addRule('all', [], [fakeSiteElement(1, 'Takeover'), fakeSiteElement(2, 'Takeover')]);
      }
    });
    module.apply().then(function (siteElements) {
      expect(siteElements.length).toEqual(1);
      done();
    });
  });

  it('supports multiple rules', function (done) {
    var module = hellobar('rules', {
      dependencies: dependencies(),
      configurator: function (configuration) {
        configuration.addRule('all', [], [fakeSiteElement(1, 'Bar')]);
        configuration.addRule('all', [], [fakeSiteElement(2, 'Slider')]);
      }
    });
    module.apply().then(function (siteElements) {
      expect(siteElements.length).toEqual(2);
      done();
    });
  });

});
