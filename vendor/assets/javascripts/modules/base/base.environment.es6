hellobar.defineModule('base.environment', ['hellobar'], function (hellobar) {

  const configuration = hellobar.createModuleConfiguration({
    userAgentProvider: 'function'
  });

  function getUserAgent() {
    const userAgentProvider = configuration.userAgentProvider();
    if (userAgentProvider) {
      return userAgentProvider();
    }
    return navigator.userAgent;
  }

  /**
   * Determines if the screen width is considered mobile for given element
   * @param siteElementData {object}
   * @returns {boolean}
   */
  function isMobileWidth(siteElementData) {
    var width = windowWidth();
    if (siteElementData.type === 'Modal') {
      return width <= 640;
    } else if (siteElementData.type === 'Slider') {
      return width <= 375;
    } else {
      return width <= 640;
    }
  }

  function windowWidth() {
    return window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
  }


  function isIE11() {
    var myNav = getUserAgent().toLowerCase();
    return myNav.indexOf('rv:11') != -1;
  }

  function isIEXOrLess(x) {
    var myNav = getUserAgent().toLowerCase();
    var version = (myNav.indexOf('msie') != -1) ? parseInt(myNav.split('msie')[1]) : false;

    if (isNaN(version) || version == null || version == false) {
      return false;
    }

    if (version <= x) {
      return true;
    }
  }

  // Returns true if the device is using mobile safari (ie, ipad / iphone)
  function isMobileSafari() {
    var ua = getUserAgent().toLowerCase();
    return (ua.indexOf('safari') > -1 && (ua.indexOf('iphone') > -1 || ua.indexOf('ipad') > -1));
  }

  function isMobileDevice() {
    return device() === 'mobile';
  }



  function device() {
    var ua = getUserAgent();
    if (ua.match(/ipad/i))
      return 'tablet';
    else if (ua.match(/(mobi|phone|ipod|blackberry|docomo)/i))
      return 'mobile';
    else if (ua.match(/(ipad|kindle|android)/i))
      return 'tablet';
    else
      return 'computer';
  }

  // TODO Semantics of this module is very controversial. Should be refactored. Namely:
  // What is exactly a 'mobile' device? Why iPad returns true in isMobileSafari but false in isMobileDevice?
  // Also we should split device and browser detection functions.

  return {
    configuration: () => configuration,
    device,
    isMobileDevice,
    isMobileWidth,
    isMobileSafari,
    isIE11,
    isIEXOrLess
  };

});
