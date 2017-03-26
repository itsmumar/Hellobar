hellobar.defineModule('base.bus', [], function() {


  // TODO -> base.bus
  // This lets users set a callback for a Hello Bar event specified by eventName (e.g. "siteElementshown")
  function on(eventName, callback) {
    if (!HB.eventCallbacks)
      HB.eventCallbacks = {};
    if (!HB.eventCallbacks[eventName])
      HB.eventCallbacks[eventName] = [];
    HB.eventCallbacks[eventName].push(callback);
  }

  // TODO -> base.bus
  // This is called internally to trigger a Hello Bar event (e.g. "siteElementshown")
  // Although it may look like no arguments are passed to trigger that is not true.
  // The first argument is the event name and all subsequent arguments are passed to
  // any callbacks on that event. So HB.trigger("foo", 1, 2) will pass the arguments (1,2)
  // to each callback set via HB.on, so HB.on("foo", function(a,b){alert(a+b)}) would alert
  // 3 in this case.
  function trigger() {
    var eventName = arguments[0];
    if (HB.eventCallbacks && HB.eventCallbacks[eventName]) {
      var l = HB.eventCallbacks[eventName].length;
      var origArgs = [];
      for (var i = 1; i < arguments.length; i++) {
        origArgs.push(arguments[i]);
      }
      for (i = 0; i < l; i++) {
        // Notice that we do setTimeout which causes the callback to happen
        // asynchronously
        (function (eventName, i) {
          setTimeout(function () {
            (HB.eventCallbacks[eventName][i]).apply(HB, origArgs);
          }, i)
        })(eventName, i);
      }
    }
  }

  return {};


});
