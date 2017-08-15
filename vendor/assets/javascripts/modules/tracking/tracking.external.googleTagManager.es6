hellobar.defineModule('tracking.external.googleTagManager',
  ['hellobar', 'base.environment'],
  function (hellobar, environment) {

  const configuration = hellobar.createModuleConfiguration({
    provider: 'function'
  });

  const gtm = () => {
    const provider = configuration.provider();

    if (provider) {
      return provider();
    }

    return window['dataLayer'];
  };

  function available () {
    return typeof gtm() === 'object';
  };

  function send(externalTracking) {
    const { category, action, label } = externalTracking;
    const event = { event: 'HelloBarEvent', category, action, label };

    const codes = environment.utmCodes();

    for (let code in codes) {
      event[code] = codes[code];
    }

    available() && gtm().push(event);
  };

  /**
   * @module Supports sending events to Google Tag Manager to track user's actions.
   */
  return {
    configuration: () => configuration,
    available,
    /**
     * Sends event data to Google Tag Manager
     * @param externalTracking {object} external tracking data structure (category, action, label are required fields).
     */
    send,
    inspect: () => ({
      gtm
    })
  };

});
