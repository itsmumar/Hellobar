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

    const trackingsByTypeAndElementId = (type, siteElementId) => {
      const allTrackings = configuration.externalTrackings() || [];
      return allTrackings.filter((tracking) => tracking.type === type && tracking.site_element_id === siteElementId);
    };

    function send(trackingType, siteElementId) {
      const processExternalTracking = (externalTracking) => {
        trackingEngines.forEach((engine) => engine.send(externalTracking));
      };
      trackingsByTypeAndElementId(trackingType, siteElementId).forEach((tracking) => processExternalTracking(tracking));
    }

    /**
     * @module Main module for all external tracking systems (Google Analytics etc.)
     */
    return {
      configuration: () => configuration,
      /**
       * Sends information about known tracking specified by trackingType.
       * @param {string} trackingType
       * @param {number} siteElementId
       */
      send
    };

  });
