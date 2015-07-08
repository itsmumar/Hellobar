$ ->
  trackClick = (target) ->
    trackingEvent = $(target).data("tracking-event")
    trackingProps = $(target).data("tracking-props")
    InternalTracking.track_current_person(trackingEvent, trackingProps)

  $(".track-click").click (event) ->
    trackClick(event.currentTarget)

  $(".track-click.activated").each ->
    trackClick(this)
