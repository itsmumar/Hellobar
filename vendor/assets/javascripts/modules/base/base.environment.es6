hellobar.defineModule('base.environment', [], function () {


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
    var myNav = navigator.userAgent.toLowerCase();
    return myNav.indexOf('rv:11') != -1;
  }

  function isIEXOrLess(x) {
    var myNav = navigator.userAgent.toLowerCase();
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
    var ua = navigator.userAgent.toLowerCase();
    return (ua.indexOf('safari') > -1 && (ua.indexOf('iphone') > -1 || ua.indexOf('ipad') > -1));
  }

  function isMobileDevice() {
    return device() === 'mobile';
  }

  function getUserAgent() {
    return navigator.userAgent;
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

  return {
    device,
    isMobileDevice,
    isMobileWidth,
    isMobileSafari,
    isIE11,
    isIEXOrLess
  };

});
