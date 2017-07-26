hellobar.defineModule('tracking.external.googleTagManager', ['hellobar'], function (hellobar) {

  const configuration = hellobar.createModuleConfiguration({ provider: 'function' });

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
    const event = 'HelloBarEvent'
    const { category, action, label } = externalTracking;

    available() && gtm().push({ event, category, action, label });
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
