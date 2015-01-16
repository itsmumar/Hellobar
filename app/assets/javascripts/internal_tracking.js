var InternalTracking = {
  track: function(type, id, eventName, props)
  {
    $.ajax({
      url: "/track/"+type+"/" + id + "/did/" + encodeURIComponent(eventName)+"?props="+encodeURIComponent(JSON.stringify(props || {})),
      type: "POST",
      dataType: "json"
    });
  },

  track_current_person: function(eventName, props)
  {
    $.ajax({
      url: "/track/current_person/did/" + encodeURIComponent(eventName)+"?props="+encodeURIComponent(JSON.stringify(props || {})),
      type: "POST",
      dataType: "json"
    });
  }
}
