hellobar.defineModule('elements.intents', ['base.environment'], function (environment) {

  let intentConditionCache = {};

  // Runs a function "payload" if the visitor meets intent-detection conditions
  function intentCheck(intentSetting, payload) {
    var visitorIntendsTo = false;

    // if intent is set to exit and we have enough mouse position data...
    if (intentSetting === 'exit') {

      // catch a keyboard move towards the address bar via onBlur event; resets onBlur state
      if (intentConditionCache.intentBodyBlurEvent) {
        visitorIntendsTo = true;
        intentConditionCache.intentBodyBlurEvent = false;
      }

      if (intentConditionCache.mousedOut) {
        visitorIntendsTo = true;
      }

      //  catch page inactive state
      if (document.hidden || document.unloaded) {
        visitorIntendsTo = true;
      }

      // if on mobile, display the bar after N ms regardless of mouse behavior
      var mobileDelaySetting = 30000;
      var date = new Date();
      if (environment.device() === 'mobile' && date.getTime() - intentConditionCache.intentStartTime > mobileDelaySetting) {
        visitorIntendsTo = true;
      }
    }

    if (visitorIntendsTo) {
      payload();
    }
  }

  // Runs a function if the visitor has scrolled to a given height.
  function scrollTargetCheck(scrollTarget, payload) {
    // scrollTarget of "bottom" and "middle" are computed during check, in case page size changes;
    // scrollTarget also accepts distance from top in pixels

    if (scrollTarget === 'bottom') {
      // arbitrary 300 pixels subtracted from page height to assume visitor will not scroll through a footer
      scrollTarget = (document.body.scrollHeight - window.innerHeight - 300);
    }
    else if (scrollTarget === 'middle') {
      // triggers just before middle of page - feels right due to polling rate
      scrollTarget = ((document.body.scrollHeight - (window.innerHeight * 2)) / 2);
    }

    // first condition checks if visitor has scrolled.
    // second condition guards against pages too small to scroll, displays immediately.
    // window.pageYOffset is same as window.scrollY, but with better compatibility.
    if (window.pageYOffset >= scrollTarget || document.body.scrollHeight <= scrollTarget + window.innerHeight) {
      payload();
    }
  }


  function initializeIntentListeners() {
    intentConditionCache = {
      mouseInTime: null,
      mousedOut: false,
      intentBodyBlurEvent: false,
      intentStartTime: (new Date()).getTime()
    };

    // When a mouse enters the document, reset the mouseOut state and
    // set the time the document was entered
    document.body.addEventListener('mouseenter', function (e) {
      if (!intentConditionCache.mouseInTime) {
        intentConditionCache.mousedOut = false;
        intentConditionCache.mouseInTime = new Date();
      }
    });

    // captures state of whether event has fired (ex: keyboard move to address bar)
    // response to this state defined by rules inside the intentCheck loop
    window.onblur = function () {
      //use timeout because not all browser render document.activeElement reference immediately
      setTimeout(function () {
        //if active (focused) element after blur event is "body", it means focus has gone outside of the document
        //otherwise active element could be a link, an input, an iframe, etc. In that case we don't trigger intent
        intentConditionCache.intentBodyBlurEvent = document.activeElement === document.body;
      }, 0);
    };

    // When the mouse leaves the document, check the current time vs when the mouse entered
    // the document.  If greater than the specified timespan, set the mouseOut state
    document.body.addEventListener('mouseleave', function (e) {
      if (intentConditionCache.mouseInTime) {
        var currentTime = new Date();
        if (currentTime.getTime() - intentConditionCache.mouseInTime.getTime() > 2000) {
          intentConditionCache.mouseInTime = null;
          intentConditionCache.mousedOut = true;
        }
      }
    });
  }

  /**
   *
   * @param viewCondition {string}
   * @param show {function}
   * @param showMinimized {function}
   */
  function applyViewCondition(viewCondition, show, showMinimized) {
    let displayCheckInterval = null;
    if (viewCondition === 'wait-5') {
      setTimeout(show, 5000);
    }
    else if (viewCondition === 'wait-10') {
      setTimeout(show, 10000);
    }
    else if (viewCondition === 'wait-30') {
      setTimeout(show, 30000);
    }
    else if (viewCondition === 'wait-60') {
      setTimeout(show, 60000);
    }
    else if (viewCondition === 'scroll-some') {
      // scroll-some is defined here as "visitor scrolls 300 pixels"
      displayCheckInterval = setInterval(function () {
        scrollTargetCheck(300, show);
      }, 500);
    }
    else if (viewCondition === 'scroll-middle') {
      displayCheckInterval = setInterval(function () {
        scrollTargetCheck("middle", show);
      }, 500);
    }
    else if (viewCondition === 'scroll-to-bottom') {
      displayCheckInterval = setInterval(function () {
        scrollTargetCheck("bottom", show);
      }, 500);
    }
    else if (viewCondition === 'exit-intent') {
      displayCheckInterval = setInterval(function () {
        intentCheck("exit", show);
      }, 100);
    }
    else if (viewCondition == 'stay-hidden') {
      setTimeout(showMinimized, 500);
    }
    else {
      show();
    }
    return displayCheckInterval;
  }

  const module = {
    initializeIntentListeners,
    applyViewCondition
  };

  return module;

});
