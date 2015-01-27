$ ->
  $(".track-click").click (event) ->
    trackingEvent = $(event.currentTarget).data("tracking-event")
    trackingProps = $(event.currentTarget).data("tracking-props")
    InternalTracking.track_current_person(trackingEvent, trackingProps)
