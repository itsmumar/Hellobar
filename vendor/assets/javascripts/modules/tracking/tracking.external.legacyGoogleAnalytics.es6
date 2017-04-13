hellobar.defineModule('tracking.external.legacyGoogleAnalytics', ['hellobar'], function (hellobar) {

  const configuration = hellobar.createModuleConfiguration({gaProvider: 'function'});

  const ga = () => {
    const gaProvider = configuration.gaProvider();

    if (gaProvider) {
      return gaProvider();
    }

    const ga = window['_gaq'];

    return typeof ga === 'object' ? ga : {push: () => null};
  };

  function send(externalTracking) {
    const { category, action, label } = externalTracking;

    ga().push(['_trackEvent', category, action, label]);
  }

  /**
   * @module Supports sending data to Legacy Google Analytics to track user's actions.
   */
  return {
    configuration: () => configuration,
    /**
     * Sends event data to Legacy Google Analytics
     * @param externalTracking {object} external tracking data structure (category, action, label are required fields).
     */
    send,
    introspect: () => ({
      ga,
      available() {
        return typeof ga().I === 'object';
      }
    })
  };

});
