hellobar.defineModule('tracking.ga', ['hellobar'], function (hellobar) {

  const configuration = hellobar.createModuleConfiguration({
    externalEvents: {
      type: Array,
      defaultValue: []
    },
    gaProvider: 'function'
  });

  let subscriptions = [];

  const eventsByType = (type) => (configuration.externalEvents() || []).filter((event) => event.type === type);

  const ga = () => {
    const gaProvider = configuration.gaProvider();
    if (gaProvider) {
      return gaProvider();
    }
    const ga = window[window['GoogleAnalyticsObject'] || 'ga'];
    return typeof ga === 'function' ? ga : () => {
      console.warn('Google Analytics not loaded on the site.');
    };
  };

  function sendGaEvent(eventType) {
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

  function sendCtaClick(externalEventType) {
    sendGaEvent(externalEventType);
  }

  function trackCtaClick(ctaElement, externalEventType) {
    //TODO do this in site_element: const ctaElement = element.querySelector('.js-cta');
    const clickHandler = (evt) => {
      sendCtaClick(externalEventType);
    };
    ctaElement.addEventListener('click', clickHandler);
    const controlObject = {
      stopTracking: () => {
        ctaElement.removeEventListener('click', clickHandler);
      }
    };
    subscriptions.push({
      element: ctaElement,
      finalize: controlObject.stopTracking
    });

    return controlObject;
  }

  function finalize() {
    subscriptions.forEach((subscription) => subscription.finalize());
    subscriptions = [];
  }


  /**
   * @module Supports sending data to Google Analytics to track user's actions.
   */
  return {
    configuration: () => configuration,
    sendCtaClick,
    trackCtaClick,
    finalize
  };

});
