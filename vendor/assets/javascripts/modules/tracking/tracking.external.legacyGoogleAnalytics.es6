hellobar.defineModule('tracking.external.legacyGoogleAnalytics', ['hellobar'], function (hellobar) {

  const configuration = hellobar.createModuleConfiguration({ provider: 'function' });

  const ga = () => {
    const provider = configuration.provider();

    if (provider) {
      return provider();
    }

    return window['_gaq'];
  };

  function available () {
    return typeof ga() === 'object';
  };

  function send(externalTracking) {
    const { category, action, label } = externalTracking;

    available() && ga().push(['_trackEvent', category, action, label]);
  };

  /**
   * @module Supports sending events to Legacy Google Analytics to track user's actions.
   */
  return {
    configuration: () => configuration,
    available,
    /**
     * Sends event data to Legacy Google Analytics
     * @param externalTracking {object} external tracking data structure (category, action, label are required fields).
     */
    send,
    inspect: () => ({
      ga,
    })
  };

});
