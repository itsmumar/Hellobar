hellobar.defineModule('tracking.external.googleAnalytics', ['hellobar'], function (hellobar) {

  const configuration = hellobar.createModuleConfiguration({gaProvider: 'function'});

  const ga = () => {
    const gaProvider = configuration.gaProvider();

    if (gaProvider) {
      return gaProvider();
    }

    const ga = window[window['GoogleAnalyticsObject'] || 'ga'];

    return typeof ga === 'function' ? ga : () => null;
  };

  function send(externalTracking) {
    const { category, action, label } = externalTracking;

    ga()('send', {
      hitType: 'event',
      eventCategory: category,
      eventAction: action,
      eventLabel: label
    });
  }

  /**
   * @module Supports sending data to Google Analytics to track user's actions.
   */
  return {
    configuration: () => configuration,
    /**
     * Sends event data to Google Analytics
     * @param externalTracking {object} external tracking data structure (category, action, label are required fields).
     */
    send,
    introspect: () => ({
      ga,
      available() {
        return typeof ga() === 'function';
      }
    })
  };

});
