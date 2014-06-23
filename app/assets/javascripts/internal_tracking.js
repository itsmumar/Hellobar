var InternalTracking = {
  track_event: function(type, id, eventName)
  {
      $.ajax({
        url: "/"+type+"/" + id + "/did/" + encodeURIComponent(eventName),
        type: "POST",
        dataType: "json"
      });
  },

  track_prop: function(type, id, propName, propValue)
  {
      $.ajax({
        url: "/"+type+"/" + id + "/has/" + encodeURIComponent(propName)+ "/of/" +encodeURIComponent(propValue),
        type: "POST",
        dataType: "json"
      });
  }
}
