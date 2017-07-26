hellobar.defineModule('tracking.external',
  ['hellobar',
    'tracking.external.googleAnalytics',
    'tracking.external.googleTagManager'],

  function (hellobar, googleAnalytics, googleTagManager) {

    const configuration = hellobar.createModuleConfiguration({
      externalTrackings: {
        type: Array,
        defaultValue: []
      }
    });

    const trackingEngines = [googleAnalytics, googleTagManager];

    const trackingsByTypeAndElementId = (type, siteElementId) => {
      const allTrackings = configuration.externalTrackings() || [];
      return allTrackings.filter((tracking) => tracking.type === type && tracking.id === siteElementId);
    };

    function available () {
      return trackingEngines.some((trackingEngine) => trackingEngine.available());
    };

    function send(trackingType, siteElementId) {
      const processExternalTracking = (externalTracking) => {
        console.log(`processExternalTracking(): with ${ externalTracking }`);
        trackingEngines.forEach((engine) => engine.send(externalTracking));
      };

      const trackings = trackingsByTypeAndElementId(trackingType, siteElementId);

      trackings.forEach((tracking) => processExternalTracking(tracking));
    };

    /**
     * @module Main module for all external tracking systems (Google Analytics etc.)
     */
    return {
      configuration: () => configuration,
      available,
      /**
       * Sends information about known tracking specified by trackingType.
       * @param {string} trackingType
       * @param {number} siteElementId
       */
      send,
      inspect: () => ({
        trackingEngines
      })
    };
  });
