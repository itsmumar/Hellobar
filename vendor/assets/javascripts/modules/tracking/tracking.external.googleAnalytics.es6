hellobar.defineModule('tracking.external.googleAnalytics', ['hellobar'], function (hellobar) {

  const configuration = hellobar.createModuleConfiguration({ provider: 'function' });

  const ga = () => {
    const provider = configuration.provider();

    if (provider) {
      return provider();
    }

    return window[window['GoogleAnalyticsObject'] || 'ga'];
  };

  const legacyGa = () => {
    const provider = configuration.provider();

    if (provider) {
      return provider();
    }

    return window['_gaq'];
  };

  function available () {
    return availableModern() || availableLegacy();
  };

  function availableModern () {
    return typeof ga() === 'function';
  };

  function availableLegacy () {
    return typeof legacyGa() === 'object';
  };

  function send(externalTracking) {
    const hitType = 'event'; // required GA value
    const { category, action, label } = externalTracking;

    // Modern Google Analytics
    availableModern() && ga()('send', {
      hitType,
      eventCategory: category,
      eventAction: action,
      eventLabel: label
    });

    // Legacy Google Analytics
    availableLegacy() && legacyGa().push(['_trackEvent', category, action, label]);
  }

  /**
   * @module Supports sending events to Google Analytics to track user's actions.
   */
  return {
    configuration: () => configuration,
    available,
    availableModern,
    availableLegacy,
    /**
     * Sends event data to Google Analytics
     * @param externalTracking {object} external tracking data structure (category, action, label are required fields).
     */
    send,
    inspect: () => ({
      ga,
      legacyGa
    })
  };

});
