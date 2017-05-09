//= require modules/core
//= require modules/elements/elements.class.alert

describe('Module elements.class.alert', function () {

  var sampleRenderedTemplate = '<div id="fake-alert">' +
    '<audio></audio>' +
    '<div id="hb-trigger"></div>' +
    '<div id="hb-popup-container"><div id="hellobar-slider"></div></div>' +
    '</div>';

  function createDependencies(previewIsActive) {
    var dependencies = {
      'base.dom': jasmine.createSpyObj('base.dom', ['addClass', 'removeClass', 'hideElement', 'showElement', 'setStyles']),
      'base.cdn': jasmine.createSpyObj('base.cdn', ['addCss']),
      'base.cdn.libraries': jasmine.createSpyObj('base.cdn.libraries', ['useFroala', 'useFontAwesome']),
      'base.site': jasmine.createSpyObj('base.site', ['secret']),
      'base.format': jasmine.createSpyObj('base.format', ['asBool']),
      'base.templating': jasmine.createSpyObj('base.templating', ['getTemplateByName', 'renderTemplate']),
      'base.preview': jasmine.createSpyObj('base.preview', ['isActive']),
      'base.coloring': jasmine.createSpyObj('base.coloring', ['colorIsBright']),
      'elements.injection': {
        inject: function (element) {
          document.body.appendChild(element);
        }
      },
      'elements.visibility': jasmine.createSpyObj('elements.visibility', ['setVisibilityControlCookie']),
      'elements.intents': jasmine.createSpyObj('elements.intents', ['applyViewCondition']),
      'elements.conversion': jasmine.createSpyObj('elements.conversion', ['converted', 'viewed']),
      'elements.class': function SiteElement(){}
    };
    dependencies['base.preview'].isActive.and.returnValue(previewIsActive);
    dependencies['base.format'].asBool.and.returnValue(true);
    dependencies['base.site'].secret.and.returnValue('abcdefghijklnmopqrstuvwxyz');
    dependencies['base.coloring'].colorIsBright.and.returnValue(true);
    dependencies['base.templating'].renderTemplate.and.returnValue(sampleRenderedTemplate);
    dependencies['base.dom'].runOnDocumentReady = function (callback) {
      callback();
    };
    return dependencies;
  }

  function doWithElement(callback, previewIsActive) {
    var dependencies = createDependencies(previewIsActive);
    var AlertElement = hellobar('elements.class.alert', {
      dependencies: dependencies
    });
    var model = {
      id: 12345
    };
    var element = new AlertElement(model);
    callback(element, dependencies);
  }


  beforeEach(function () {
    hellobar.finalize();

  });

  it('provides AlertElement class and is capable of creating instances', function (done) {
    doWithElement(function (element) {
      expect(typeof element).toEqual('object');
      expect(typeof element.model()).toEqual('object');
      expect(element.id).toEqual(12345);
      expect(element);
      element.remove();
      done();
    });
  });

  it('supports element attaching', function (done) {
    doWithElement(function (element) {
      element.attach();
      setTimeout(function () {
        expect(typeof element.contentDocument()).toEqual('object');
        expect(element.contentDocument().getElementById('fake-alert')).not.toBeNull();
        element.remove();
        done();
      }, 200);
    });
  });

  it('can show and hide itself and popup', function (done) {
    doWithElement(function (element) {
      element.attach();
      setTimeout(function () {
        element.hide();
        expect(element.isVisible()).toBeFalsy();
        element.show();
        expect(element.isVisible()).toBeTruthy();
        element.hidePopup();
        expect(element.isPopupVisible()).toBeFalsy();
        element.showPopup();
        expect(element.isPopupVisible()).toBeTruthy();
        element.hidePopup();
        expect(element.isPopupVisible()).toBeFalsy();
        element.remove();
        done();
      }, 100);
    });
  });

  it('returns correct CSS classes', function (done) {
    doWithElement(function (element) {
      element.attach();
      setTimeout(function () {
        expect(element.cssClasses().brightness()).toEqual('light');
        element.remove();
        done();
      }, 100);
    });
  });

  it('supports notification', function (done) {
    doWithElement(function (element, dependencies) {
      element.attach();
      setTimeout(function () {
        element.contentDocument().querySelector('audio').play = function () {
        };
        element.notify();
        expect(dependencies['elements.visibility'].setVisibilityControlCookie).toHaveBeenCalled();
        element.remove();
        done();
      }, 100);
    });
  });

  it('does not notify in the preview mode', function (done) {
    doWithElement(function (element, dependencies) {
      element.attach();
      setTimeout(function () {
        element.notify();
        expect(dependencies['elements.visibility'].setVisibilityControlCookie).not.toHaveBeenCalled();
        element.remove();
        done();
      }, 100);
    }, true);
  });

});
