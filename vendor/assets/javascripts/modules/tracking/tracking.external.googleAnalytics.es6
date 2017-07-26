hellobar.defineModule('tracking.external.googleAnalytics', ['hellobar'], function (hellobar) {

  const configuration = hellobar.createModuleConfiguration({ provider: 'function' });

  const ga = () => {
    const provider = configuration.provider();

    if (provider) {
      return provider();
    }

    return window[window['GoogleAnalyticsObject'] || 'ga'];
  };

  function available () {
    return typeof ga() === 'function';
  };

  function send(externalTracking) {
    const hitType = 'event';
    const { category, action, label } = externalTracking;

    available() && ga()('send', {
      hitType,
      eventCategory: category,
      eventAction: action,
      eventLabel: label
    });
  }

  /**
   * @module Supports sending events to Google Analytics to track user's actions.
   */
  return {
    configuration: () => configuration,
    available,
    /**
     * Sends event data to Google Analytics
     * @param externalTracking {object} external tracking data structure (category, action, label are required fields).
     */
    send,
    inspect: () => ({
      ga
    })
  };

});
