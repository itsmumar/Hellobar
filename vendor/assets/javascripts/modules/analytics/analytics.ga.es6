hellobar.defineModule('analytics.ga', ['hellobar'], function (hellobar) {

  const configuration = hellobar.createModuleConfiguration({
    analyticsEvents: {
      type: Array,
      defaultValue: []
    },
    gaProvider: 'function'
  });

  const eventsByType = (type) => (configuration.analyticsEvents() || []).filter((event) => event.type === type);

  const ga = () => {
    const gaProvider = configuration.gaProvider();
    if (gaProvider) {
      return gaProvider();
    }
    const ga = window[window['GoogleAnalyticsObject'] || 'ga'];
    return typeof ga === 'function' ? ga : () => null;
  };

  function send(eventType) {
    const processAnalyticsEvent = (event) => {
      const { category, action, label } = event;
      ga()('send', {
        hitType: 'event',
        eventCategory: category,
        eventAction: action,
        eventLabel: label
      });
    };
    eventsByType(eventType).forEach((event) => processAnalyticsEvent(event));
  }

  /**
   * @module Supports sending data to Google Analytics to track user's actions.
   */
  return {
    configuration: () => configuration,
    send
  };

});
