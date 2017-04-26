hellobar.defineModule('base.metainfo',
  ['hellobar'],
  function (hellobar) {
    const configuration = hellobar.createModuleConfiguration({
      version: 'string',
      timestamp: 'string'
    });

    return {
      configuration: () => configuration,
      version: () => configuration.version(),
      timestamp: () => configuration.timestamp(),
      info: () => `version ${configuration.version()} was generated at ${configuration.timestamp()}`
    };
  });
