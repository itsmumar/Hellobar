hellobar.defineModule('elements.visibility', [], function() {

  // TODO -> elements.visibility
  /**
   * Generates a name for visibility control cookie
   * @param cookieType {string}
   * @param siteElementId {number}
   * @returns {string}
   */
  function visibilityControlCookieName(cookieType, siteElementId) {
    return 'HB-visibilityControl-' + cookieType + '-' + siteElementId;
  }

  // TODO -> elements.visibility
  /**
   * Stores visibility control information with corresponding expiration date.
   * siteElement.settings.cookie_settings is used to calculate expiration.
   * @param {string} cookieType
   * @param {object} siteElement
   */
  function setVisibilityControlCookie(cookieType, siteElement) {
    function settingName() {
      switch (cookieType) {
        case 'dismiss':
          return 'duration';
        case 'success':
          return 'success_duration';
        default:
          return 'duration';
      }
    }

    function getDayCountFromSettings() {
      return siteElement && siteElement.settings && siteElement.settings.cookie_settings
        && siteElement.settings.cookie_settings[settingName()];
    }

    var dayCount = getDayCountFromSettings();
    dayCount = parseInt(dayCount);

    if (dayCount > 0) {
      var cookieName = HB.visibilityControlCookieName(cookieType, siteElement.id);
      var cookieValue = new Date().toString();
      HB.sc(cookieName, cookieValue, dayCount);
    }
  },

  // TODO -> elements.visibility
  /**
   * Checks if the site element should be shown considering visibility control cookies.
   * If at least one visibility control cookie prohibits the element then it won't be shown.
   * @param siteElement
   * @returns {boolean}
   */
  function checkVisibilityControlCookies(siteElement) {
    var supportedCookieTypes = ['dismiss', 'success'];
    var result = true;
    supportedCookieTypes.forEach(function (cookieType) {
      var cookieName = HB.visibilityControlCookieName(cookieType, siteElement.id);
      if (HB.gc(cookieName)) {
        result = false;
      }
    });
    return result;
  }

  // TODO -> elements.visibility (make it inner)
  function nonMobileClickToCall(siteElementData) {
    return siteElementData.subtype === 'call' && !HB.isMobileDevice();
  }

  // TODO -> elements.visibility
  /**
   * Determines if an element should be displayed
   * @param siteElementData {object}
   * @returns {boolean}
   */
  function shouldShowElement(siteElementData) {
    function shouldHideElementConsideringTypeAndScreenWidth() {
      // A topbar is the only style which is displayed on all screen sizes
      return (siteElementData.type !== 'Bar' && HB.isMobileWidth(siteElementData));
    }

    // Treat hidden elements *DIFFERENTLY* -- i.e. show them (even though
    // the visibility control cookie is *set*) *but* show them minimized
    if ((siteElementData.type === 'Bar' || siteElementData.type === 'Slider') // Bars & Sliders only
      && !HB.checkVisibilityControlCookies(siteElementData) // with a visibility cookie set (user hid it)
      && !HB.updatedSinceLastVisit(siteElementData) // not updated since last visit
      && !shouldHideElementConsideringTypeAndScreenWidth() // eligible for mobile
      && !HB.nonMobileClickToCall(siteElementData)) { // something

      // show, but in a hidden (minimized) state
      siteElementData.view_condition = 'stay-hidden';
      return true;
    }

    // Skip the site element if they have already seen/dismissed it
    // and it hasn't been changed since then and the user has not specified
    // that we show it regardless
    if ((!HB.checkVisibilityControlCookies(siteElementData) && !HB.updatedSinceLastVisit(siteElementData))
      || shouldHideElementConsideringTypeAndScreenWidth()
      || HB.nonMobileClickToCall(siteElementData)) {
      return false;
    } else {
      return true;
    }
  }

  // TODO -> elements.visibility (make it inner)
  function updatedSinceLastVisit(siteElement) {
    var lastVisited = new Date(HB.getSiteElementData(siteElement.id, 'lv') * 1000);
    var lastUpdated = new Date(siteElement.updated_at);

    return lastUpdated > lastVisited;
  }




  const module = {
    initialize: () => null
  };

  return module;

});

