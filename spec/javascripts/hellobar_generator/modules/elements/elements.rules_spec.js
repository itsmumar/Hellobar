//= require modules/core
//= require modules/base/base.deferred
//= require modules/elements/elements.rules

describe('Module elements.rules', function () {

  function dependencies(visitorDataValue) {
    var dependencies = {
      'base.format': {
        normalizeUrl: function (url) {
          return url;
        }
      },
      'base.environment': jasmine.createSpyObj('base.environment', ['isMobileDevice']),
      'base.timezone': jasmine.createSpyObj('base.timezone', ['nowInTimezone']),
      'base.deferred': hellobar('base.deferred'),
      'visitor': jasmine.createSpyObj('visitor', ['getData']),
      'elements.visibility': jasmine.createSpyObj('elements.visibility', ['shouldShowElement']),
      'elements.data': jasmine.createSpyObj('elements.data', ['getData', 'setData'])
    };

    dependencies['base.timezone'].nowInTimezone.and.returnValue(new Date());
    dependencies['visitor'].getData.and.returnValue(visitorDataValue);
    dependencies['elements.visibility'].shouldShowElement.and.returnValue(true);

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
    var module = hellobar('elements.rules', {
      dependencies: dependencies(),
      configurator: function (configuration) {
        configuration.addRule('all', [], [fakeSiteElement(1, 'Bar'), fakeSiteElement(2, 'Slider')]);
      }
    });
    module.applyRules().then(function (siteElements) {
      expect(siteElements.length).toEqual(2);
      done();
    });
  });

  it('does not allow to show multiple elements with the same type', function (done) {
    var module = hellobar('elements.rules', {
      dependencies: dependencies(),
      configurator: function (configuration) {
        configuration.addRule('all', [], [fakeSiteElement(1, 'Takeover'), fakeSiteElement(2, 'Takeover')]);
      }
    });
    module.applyRules().then(function (siteElements) {
      expect(siteElements.length).toEqual(1);
      done();
    });
  });

  it('supports multiple rules', function (done) {
    var module = hellobar('elements.rules', {
      dependencies: dependencies(),
      configurator: function (configuration) {
        configuration.addRule('all', [], [fakeSiteElement(1, 'Bar')]);
        configuration.addRule('all', [], [fakeSiteElement(2, 'Slider')]);
      }
    });
    module.applyRules().then(function (siteElements) {
      expect(siteElements.length).toEqual(2);
      done();
    });
  });

  it('supports conditions on device', function (done) {
    var module = hellobar('elements.rules', {
      dependencies: dependencies('desktop'),
      configurator: function (configuration) {
        configuration.addRule('all', [{segment: 'dv', operand: 'is', value: 'mobile'}], [fakeSiteElement(100, 'Bar')]);
        configuration.addRule('all', [{segment: 'dv', operand: 'is', value: 'desktop'}], [fakeSiteElement(200, 'Bar')]);
      }
    });
    module.applyRules().then(function (siteElements) {
      expect(siteElements.length).toEqual(1);
      expect(siteElements[0].id).toEqual(200);
      done();
    });
  });

  it('supports conditions on country', function (done) {
    var module = hellobar('elements.rules', {
      dependencies: dependencies('RU'),
      configurator: function (configuration) {
        configuration.addRule('all', [{segment: 'gl_ctr', operand: 'is', value: 'RU'}], [fakeSiteElement(100, 'Bar')]);
        configuration.addRule('all', [{segment: 'gl_ctr', operand: 'is', value: 'US'}], [fakeSiteElement(200, 'Bar')]);
      }
    });
    module.applyRules().then(function (siteElements) {
      expect(siteElements.length).toEqual(1);
      expect(siteElements[0].id).toEqual(100);
      done();
    });
  });

  it('supports logical AND operation', function (done) {
    var module = hellobar('elements.rules', {
      dependencies: dependencies('RU'),
      configurator: function (configuration) {
        configuration.addRule('all', [
          {segment: 'gl_ctr', operand: 'is', value: 'RU'},
          {segment: 'gl_ctr', operand: 'is', value: 'US'}
        ], [fakeSiteElement(100, 'Bar')]);
      }
    });
    module.applyRules().then(function (siteElements) {
      expect(siteElements.length).toEqual(0);
      done();
    });
  });

  it('supports logical OR operation', function (done) {
    var module = hellobar('elements.rules', {
      dependencies: dependencies('RU'),
      configurator: function (configuration) {
        configuration.addRule('any', [
          {segment: 'gl_ctr', operand: 'is', value: 'RU'},
          {segment: 'gl_ctr', operand: 'is', value: 'US'}
        ], [fakeSiteElement(300, 'Bar')]);
      }
    });
    module.applyRules().then(function (siteElements) {
      expect(siteElements.length).toEqual(1);
      expect(siteElements[0].id).toEqual(300);
      done();
    });
  });


});
