hellobar.defineModule('tracking.external',
  ['hellobar', 'tracking.external.googleAnalytics', 'tracking.external.legacyGoogleAnalytics'],
  function (hellobar, googleAnalytics, legacyGoogleAnalytics) {

    const configuration = hellobar.createModuleConfiguration({
      externalTrackings: {
        type: Array,
        defaultValue: []
      }
    });

    const trackingEngines = [googleAnalytics, legacyGoogleAnalytics];

    const trackingsByType = (type) => (configuration.externalTrackings() || []).filter((tracking) => tracking.type === type);

    function send(trackingType) {
      const processExternalTracking = (externalTracking) => {
        trackingEngines.forEach((engine) => engine.send(externalTracking));
      };
      trackingsByType(trackingType).forEach((tracking) => processExternalTracking(tracking));
    }

    /**
     * @module Main module for all external tracking systems (Google Analytics etc.)
     */
    return {
      configuration: () => configuration,
      /**
       * Sends information about known tracking specified by trackingType.
       * @param {string} trackingType
       */
      send
    };

  });
