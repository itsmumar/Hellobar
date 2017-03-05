(function () {

  var moduleWrappers = {};

  function hellobar() {
    return hellobar.module.apply(this, arguments);
  }

  function HellobarException(message) {
    var _message = 'HelloBar: ' + message;
    this.message = function () {
      return _message;
    };
    this.toString = function () {
      return _message;
    };
  }

  function getModuleSafe(moduleName, configurator) {
    var moduleWrapper = moduleWrappers[moduleName];
    if (!moduleWrapper) {
      throw new HellobarException('Cannot find HelloBar module ' + moduleName +
        '. Please define the module with hellobar.defineModule call');
    }

    function loadDependencies() {
      var dependencyNames = moduleWrapper.dependencyNames || [];
      return dependencyNames.map(function (dependencyName) {
        return getModuleSafe(dependencyName);
      });
    }

    if (!moduleWrapper.module) {
      var dependencies = loadDependencies();
      moduleWrapper.module = moduleWrapper.moduleFactory.apply(hellobar, dependencies);
    }
    if (!moduleWrapper.initialized) {
      if (moduleWrapper.module.initialize) {
        moduleWrapper.module.initialize(configurator);
      } else if (configurator && moduleWrapper.module.configuration) {
        configurator.call(moduleWrapper.module, moduleWrapper.module.configuration());
      }
      moduleWrapper.initialized = true;
    }
    return moduleWrapper.module;
  }

  /**
   * Gets the module instance. This method lazily instantiates the module if it doesn't exists.
   * @param moduleName {string}
   * @param options {object}
   */
  hellobar.module = function (moduleName, options) {
    var configurator = (options && options.configurator) || null;
    return getModuleSafe(moduleName, configurator);
  };

  hellobar.finalize = function () {
    for (var moduleName in moduleWrappers) {
      if (moduleWrappers.hasOwnProperty(moduleName)) {
        var moduleWrapper = moduleWrappers[moduleName];
        moduleWrapper.finalize && moduleWrapper.finalize();
        moduleWrapper.module = null;
        moduleWrapper.initialized = false;
      }
    }
  };

  hellobar.defineModule = function (moduleName, dependencyNames, moduleFactory) {
    if (!moduleWrappers[moduleName]) {
      moduleWrappers[moduleName] = {
        dependencyNames: dependencyNames,
        moduleFactory: moduleFactory,
        initialized: false
      };
    } else {
      console.warn('HelloBar: Module ' + moduleName + ' has been already defined');
    }
  };

  window.hellobar = window.hellobar || hellobar;

  return hellobar;

})();
