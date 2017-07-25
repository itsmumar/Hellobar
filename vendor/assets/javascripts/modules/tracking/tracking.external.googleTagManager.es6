hellobar.defineModule('tracking.external.googleTagManager', ['hellobar'], function (hellobar) {

  const configuration = hellobar.createModuleConfiguration({ gtmProvider: 'function' });

  const gtm = () => {
    const gtmProvider = configuration.gtmProvider();

    if (gtmProvider) {
      return gtmProvider();
    }

    const gtm = window['dataLayer'];

    return typeof gtm === 'object' ? gtm : { push: () => null };
  };

  function send(externalTracking) {
    const { category, action, label } = externalTracking;
    const event = 'HelloBarEvent'

    gtm().push({ event, category, action, label });
  };

  /**
   * @module Supports sending events to Google Tag Manager to track user's actions.
   */
  return {
    configuration: () => configuration,
    /**
     * Sends event data to Google Tag Manager
     * @param externalTracking {object} external tracking data structure (category, action, label are required fields).
     */
    send,
    inspect: () => ({
      gtm,
      available() {
        return typeof gtm().hide === 'object';
      }
    })
  };

});
