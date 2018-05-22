hellobar.defineModule('base.metainfo',
  ['hellobar'],
  function (hellobar) {
    const configuration = hellobar.createModuleConfiguration({
      version: 'string',
      timestamp: 'string',
      environment: 'string'
    });

    return {
      configuration: () => configuration,
      environment: () => configuration.environment(),
      isTest: () => configuration.environment() === 'test',
      version: () => configuration.version(),
      timestamp: () => configuration.timestamp(),
      info: () => `version ${configuration.version()} was generated at ${configuration.timestamp()}`
    };
  });
