hellobar.defineModule('tracking.ga', ['hellobar'], function (hellobar) {

  const configuration = hellobar.createModuleConfiguration({
    externalEvents: {
      type: Array,
      defaultValue: []
    },
    gaProvider: 'function'
  });

  const eventsByType = (type) => (configuration.externalEvents() || []).filter((event) => event.type === type);

  const ga = () => {
    const gaProvider = configuration.gaProvider();
    if (gaProvider) {
      return gaProvider();
    }
    const ga = window[window['GoogleAnalyticsObject'] || 'ga'];
    return typeof ga === 'function' ? ga : () => null;
  };

  function send(eventType) {
    const processExternalEvent = (externalEvent) => {
      const { category, action, label } = externalEvent;
      ga()('send', {
        hitType: 'event',
        eventCategory: category,
        eventAction: action,
        eventLabel: label
      });
    };
    eventsByType(eventType).forEach((externalEvent) => processExternalEvent(externalEvent));
  }

  /**
   * @module Supports sending data to Google Analytics to track user's actions.
   */
  return {
    configuration: () => configuration,
    send
  };

});
