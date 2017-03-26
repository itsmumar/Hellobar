hellobar.defineModule('elements.intents', [], function() {

  // TODO -> elements.intents ???
  // TODO it's for intentCheck from site_element.es6
  // TODO rename payload
  // Runs a function "payload" if the visitor meets intent-detection conditions
  function intentCheck(intentSetting, payload) {
    var vistorIntendsTo = false;

    // if intent is set to exit and we have enough mouse position data...
    if (intentSetting === 'exit') {

      // catch a keyboard move towards the address bar via onBlur event; resets onBlur state
      if (HB.intentConditionCache.intentBodyBlurEvent) {
        vistorIntendsTo = true;
        HB.intentConditionCache.intentBodyBlurEvent = false;
      }

      if (HB.intentConditionCache.mousedOut) {
        vistorIntendsTo = true;
      }

      //  catch page inactive state
      if (document.hidden || document.unloaded) {
        vistorIntendsTo = true
      }

      // if on mobile, display the bar after N ms regardless of mouse behavior
      var mobileDelaySetting = 30000;
      var date = new Date();
      if (HB.device() === 'mobile' && date.getTime() - HB.intentConditionCache.intentStartTime > mobileDelaySetting) {
        vistorIntendsTo = true
      }
    }

    if (vistorIntendsTo) {
      payload();
    }
  }


  // TODO called from setupIFrame from site_element.es6
  // TODO where it should be?
  function initializeIntentListeners() {
    HB.intentConditionCache = {
      mouseInTime: null,
      mousedOut: false,
      intentBodyBlurEvent: false,
      intentStartTime: (new Date()).getTime()
    };

    // When a mouse enters the document, reset the mouseOut state and
    // set the time the document was entered
    document.body.addEventListener('mouseenter', function (e) {
      if (!HB.intentConditionCache.mouseInTime) {
        HB.intentConditionCache.mousedOut = false;
        HB.intentConditionCache.mouseInTime = new Date();
      }
    });

    // captures state of whether event has fired (ex: keyboard move to address bar)
    // response to this state defined by rules inside the intentCheck loop
    window.onblur = function () {
      //use timeout because not all browser render document.activeElement reference immediately
      setTimeout(function () {
        //if active (focused) element after blur event is "body", it means focus has gone outside of the document
        //otherwise active element could be a link, an input, an iframe, etc. In that case we don't trigger intent
        HB.intentConditionCache.intentBodyBlurEvent = document.activeElement === document.body;
      }, 0);
    };

    // When the mouse leaves the document, check the current time vs when the mouse entered
    // the document.  If greater than the specified timespan, set the mouseOut state
    document.body.addEventListener('mouseleave', function (e) {
      if (HB.intentConditionCache.mouseInTime) {
        var currentTime = new Date();
        if (currentTime.getTime() - HB.intentConditionCache.mouseInTime.getTime() > 2000) {
          HB.intentConditionCache.mouseInTime = null;
          HB.intentConditionCache.mousedOut = true;
        }
      }
    });
  }

  const module = {
    initialize: () => null
  };

  return module;

});
