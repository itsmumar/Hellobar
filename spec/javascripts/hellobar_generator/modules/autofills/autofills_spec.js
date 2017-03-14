//= require modules/core
//= require modules/autofills/autofills

describe('Module base.dom', function () {
  var module;

  function dependencies() {
    var storedValue = 'autofilled-value';
    var dependencies = {
      'base.storage': jasmine.createSpyObj('base.storage', ['getValue', 'setValue']),
      'base.dom': {
        forAllDocuments: function(callback) {
          callback(document);
        },
        runOnDocumentReady: function(callback) {
          callback();
        }
      }
    };
    dependencies['base.storage'].getValue.and.returnValue(storedValue);
    return dependencies;
  }

  beforeEach(function () {
    var autofills = [{id: 12345, site_id: 2, populate_selector: '#test-input', listen_selector: '#test-input'}];
    module = hellobar('autofills', {
      dependencies: dependencies(),
      configurator: function (configuration) {
        configuration.autofills(autofills).autoRun(false);
      }
    });
  });

  afterEach(function () {
    module.finalize();
  });

  it('provides proper configuration', function () {
    expect(module.configuration()).toBeDefined();
    expect(module.configuration().autofills()).toBeDefined();
    expect(module.configuration().autofills().length).toEqual(1);
    expect(module.configuration().autoRun()).toEqual(false);
  });

  it('runs successfully', function () {
    document.body.innerHTML = '<div><input id="test-input"></div>';
    module.run();
    expect(document.getElementById('test-input').value).toEqual('autofilled-value');
    document.body.innerHTML = '';
  });

});
