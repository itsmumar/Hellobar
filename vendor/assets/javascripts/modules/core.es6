(function () {

  var moduleWrappers = {};

  /**
   * 'hellobar' is HelloBar JS API Core.
   * 'hellobar' function is the shorthand for 'hellobar.module' - i.e.
   * @example
   * <pre>
   * hellobar.module('myFavoriteModule') // long syntax
   * hellobar('myFavoriteModule') // short syntax, does the same as above
   * </pre>
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
  class HellobarException extends Error {
    constructor(message) {
      super(message);
      this.name = this.constructor.name;
      if (typeof Error.captureStackTrace === 'function') {
        Error.captureStackTrace(this, this.constructor);
      } else {
        this.stack = (new Error(message)).stack;
      }
    }
  }

  function verifiedToBeNonEmpty(value, errorMessage) {
    if (!value) {
      throw new HellobarException(errorMessage || 'Required value is empty');
    }
    return value;
  }

  function getModuleSafe(moduleName, configurator, dependencies, allowUndefined) {
    var moduleWrapper = moduleWrappers[moduleName];
    if (!moduleWrapper) {
      if (allowUndefined) {
        return undefined;
      } else {
        throw new HellobarException('Cannot find HelloBar module ' + moduleName +
          '. Please define the module with hellobar.defineModule call');
      }
    }

    function loadDependencies() {
      var dependencyNames = moduleWrapper.dependencyNames || [];
      return dependencyNames.map(function (dependencyName) {
        if (dependencyName === 'hellobar') {
          return hellobar;
        }
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
    var allowUndefined = (options && options.allowUndefined) || false;
    return getModuleSafe(moduleName, configurator, dependencies, allowUndefined);
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

  /**
   * Generic class for HelloBar module configuration.
   * It supports setters/setters for any given settings (with optional type checking).
   * @param settings {object} Key name is parameter name, value is just type or type with defaultValue
   * @constructor
   */
  function ModuleConfiguration(settings) {
    var that = this;

    function checkTypeIsCorrect(value, type) {
      if (typeof type === 'string') {
        if (typeof value !== type) {
          throw new HellobarException('Wrong value type. Type ' + type + ' expected, but ' + typeof value + ' is given');
        }
      } else if (typeof type === 'function') {
        if (!(value instanceof type)) {
          throw new HellobarException('Wrong value type. Value does not match the required constructor');
        }
      }
    }

    function addSetting(name, type, defaultValue) {
      var _value = defaultValue;
      that[name] = function (value) {
        if (typeof value === 'undefined') {
          return _value;
        } else {
          type && checkTypeIsCorrect(value, type);
          _value = value;
          return that;
        }
      };
    }

    if (settings) {
      for (var name in settings) {
        if (settings.hasOwnProperty(name)) {
          var setting = settings[name];
          if (typeof setting === 'string' || typeof setting === 'function') {
            addSetting(name, setting);
          } else if (typeof setting === 'object') {
            addSetting(name, setting.type, setting.defaultValue);
          }

        }
      }
    }
  }

  /**
   * Creates an instance of module configuration by given settings definition.
   * @param settings
   * @returns {ModuleConfiguration} instance of module configuration
   * @example
   * <pre>
   * var configuration = hellobar.createModuleConfiguration({
   *   autoRun: 'boolean', // boolean setting
   *   limit: 'number', // number setting
   *   caption: 'string', // string setting
   *   expirationPolicy: 'function', // function setting
   *   itemRenderer: ItemRenderer, // setting specified with custom class
   *   items: Array, // array
   *   attachment: null, // setting with no type checking
   *   buttonText: { // setting with explicit defaultValue
   *     type: 'string',
   *     defaultValue: 'Click me'
   *   }
   * });
   * </pre>
   */
  hellobar.createModuleConfiguration = function (settings) {
    return new ModuleConfiguration(settings);
  };

  window.hellobar = window.hellobar || hellobar;

  return hellobar;

})();
