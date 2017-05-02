hellobar.defineModule('elements.visibility',
  ['base.storage', 'base.environment', 'elements.data'],
  function (storage, environment, elementsData) {

    /**
     * Generates a name for visibility control cookie
     * @param cookieType {string}
     * @param siteElementId {number}
     * @returns {string}
     */
    function visibilityControlCookieName(cookieType, siteElementId) {
      return 'HB-visibilityControl-' + cookieType + '-' + siteElementId;
    }

    function expireVisibilityControlCookie(cookieType, siteElementId) {
      var cookieName = visibilityControlCookieName(cookieType, siteElementId);
      storage.setValue(cookieName, JSON.stringify({}), new Date().toString());
    }

    /**
     * Stores visibility control information with corresponding expiration date.
     * siteElement.settings.cookie_settings is used to calculate expiration.
     * @param {string} cookieType
     * @param {object} siteElement
     */
    function setVisibilityControlCookie(cookieType, siteElement) {
      const siteElementModel = siteElement.model ? siteElement.model() : siteElement;

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
        return siteElementModel && siteElementModel.settings && siteElementModel.settings.cookie_settings
          && siteElementModel.settings.cookie_settings[settingName()];
      }

      var dayCount = getDayCountFromSettings();
      dayCount = parseInt(dayCount);

      if (dayCount > 0) {
        var cookieName = visibilityControlCookieName(cookieType, siteElementModel.id);
        var cookieValue = new Date().toString();
        storage.setValue(cookieName, cookieValue, dayCount);
      }
    }

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
        var cookieName = visibilityControlCookieName(cookieType, siteElement.id);
        if (storage.getValue(cookieName)) {
          result = false;
        }
      });
      return result;
    }

    function nonMobileClickToCall(siteElementModel) {
      return siteElementModel.subtype === 'call' && !environment.isMobileDevice();
    }

    /**
     * Determines if an element should be displayed
     * @param siteElementModel {object}
     * @returns {boolean}
     */
    function shouldShowElement(siteElementModel) {
      function shouldHideElementConsideringTypeAndScreenWidth() {
        // A topbar is the only style which is displayed on all screen sizes
        return (siteElementModel.type !== 'Bar' && environment.isMobileWidth(siteElementModel));
      }

      // Treat hidden elements *DIFFERENTLY* -- i.e. show them (even though
      // the visibility control cookie is *set*) *but* show them minimized
      // Bars & Sliders & Alerts only
      if ((siteElementModel.type === 'Bar' || siteElementModel.type === 'Slider' || siteElementModel.type === 'Alert')
        && !checkVisibilityControlCookies(siteElementModel) // with a visibility cookie set (user hid it)
        && !updatedSinceLastVisit(siteElementModel) // not updated since last visit
        && !shouldHideElementConsideringTypeAndScreenWidth() // eligible for mobile
        && !nonMobileClickToCall(siteElementModel)) { // something
        // show, but in a hidden (minimized) state
        siteElementModel.view_condition = 'stay-hidden';
        return true;
      }

      // Skip the site element if they have already seen/dismissed it
      // and it hasn't been changed since then and the user has not specified
      // that we show it regardless
      if ((!checkVisibilityControlCookies(siteElementModel) && !updatedSinceLastVisit(siteElementModel))
        || shouldHideElementConsideringTypeAndScreenWidth()
        || nonMobileClickToCall(siteElementModel)) {
        return false;
      } else {
        return true;
      }
    }

    function updatedSinceLastVisit(siteElementModel) {
      var lastVisited = new Date(elementsData.getData(siteElementModel.id, 'lv') * 1000);
      var lastUpdated = new Date(siteElementModel.updated_at);
      return lastUpdated > lastVisited;
    }

    return {
      setVisibilityControlCookie,
      expireVisibilityControlCookie,
      shouldShowElement,
      inspect: () => ({
        allCookies() {
          let inspectResult = {};
          for (let i = 0; i < localStorage.length; i++) {
            const key = localStorage.key(i);
            key.indexOf('HB-visibilityControl-') === 0 && (inspectResult[key] = localStorage.getItem(key));
          }
          return inspectResult;
        }
      })
    };

  });

