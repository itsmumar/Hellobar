(function () {

  var moduleWrappers = {};

  /**
   * 'hellobar' is HelloBar JS API Core.
   * 'hellobar' function is the shorthand for 'hellobar.module' - i.e.
   * @example
   * hellobar.module('myFavoriteModule') // long syntax
   * hellobar('myFavoriteModule') // short syntax, does the same as above
   * @returns {Function|Object}
   */
  function hellobar() {
    return hellobar.module.apply(this, arguments);
  }

  /**
   * Base HelloBar exception class.
   * For example, the exception is raised when dependency management issue is detected.
   * @param message {string} error text
   * @constructor
   */
  function HellobarException(message) {
    var _message = 'HelloBar: ' + message;
    this.message = function () {
      return _message;
    };
    this.toString = function () {
      return _message;
    };
  }

  function verifiedToBeNonEmpty(value, errorMessage) {
    if (!value) {
      throw new HellobarException(errorMessage || 'Required value is empty');
    }
    return value;
  }

  function getModuleSafe(moduleName, configurator, dependencies) {
    var moduleWrapper = moduleWrappers[moduleName];
    if (!moduleWrapper) {
      throw new HellobarException('Cannot find HelloBar module ' + moduleName +
        '. Please define the module with hellobar.defineModule call');
    }

    function loadDependencies() {
      var dependencyNames = moduleWrapper.dependencyNames || [];
      return dependencyNames.map(function (dependencyName) {
        return dependencies ?
          verifiedToBeNonEmpty(dependencies[dependencyName], 'Dependency ' + dependencyName + ' is not specified') :
          getModuleSafe(dependencyName);
      });
    }

    if (!moduleWrapper.module) {
      var loadedDependencies = loadDependencies();
      moduleWrapper.module = moduleWrapper.moduleFactory.apply(hellobar, loadedDependencies);
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
   * We can provide options (currently we support configurator
   * (function that gets module configuration as a parameter and sets up the configuration)
   * and dependencies (hash object of explicitly specified module dependencies -
   * this technique is especially useful for unit testing).
   * @param moduleName {string} unique module name
   * @param options {object}
   * @returns {function|object} initialized module instance
   */
  hellobar.module = function (moduleName, options) {
    var configurator = (options && options.configurator) || null;
    var dependencies = (options && options.dependencies) || null;
    return getModuleSafe(moduleName, configurator, dependencies);
  };

  /**
   * Finalizes all the registered modules.
   * If module wants to do some actions on finalization
   * it should provide 'finalize' method and the actions should be put there.
   */
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

  /**
   * Registers module definition.
   * This function does not perform module creation/initialization.
   * @param moduleName {string}
   * @param dependencyNames {array} array of strings - i.e. required modules' names
   * @param moduleFactory {function} function that creates a module instance
   */
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
