hellobar.defineModule('base.bus', ['hellobar'], function(hellobar) {

  let eventCallbacks = {};

  // This lets users set a callback for a Hello Bar event specified by eventName (e.g. "siteElementshown")
  function on(eventName, callback) {
    if (!eventCallbacks[eventName]) {
      eventCallbacks[eventName] = [];
    }
    eventCallbacks[eventName].push(callback);
  }

  // This is called internally to trigger a Hello Bar event (e.g. "siteElementshown")
  // Although it may look like no arguments are passed to trigger that is not true.
  // The first argument is the event name and all subsequent arguments are passed to
  // any callbacks on that event. So HB.trigger("foo", 1, 2) will pass the arguments (1,2)
  // to each callback set via HB.on, so HB.on("foo", function(a,b){alert(a+b)}) would alert
  // 3 in this case.
  function trigger() {
    var eventName = arguments[0];
    if (eventCallbacks && eventCallbacks[eventName]) {
      var l = eventCallbacks[eventName].length;
      var origArgs = [];
      for (var i = 1; i < arguments.length; i++) {
        origArgs.push(arguments[i]);
      }
      for (i = 0; i < l; i++) {
        // Notice that we do setTimeout which causes the callback to happen
        // asynchronously
        (function (eventName, i) {
          setTimeout(function () {
            (eventCallbacks[eventName][i]).apply(hellobar, origArgs);
          }, i)
        })(eventName, i);
      }
    }
  }

  return {
    on,
    trigger
  };

});
