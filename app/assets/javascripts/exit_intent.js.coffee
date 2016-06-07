$ ->
  dont_leave_triggered = false

  exit_intent_modal_present = ->
    elm = $('#exit-intent-modal-template')
    if elm.length > 0
      true
    else
      false

  $('body').on 'mouseleave', (e) ->
    if e.offsetY - $(window).scrollTop() < 0 && !dont_leave_triggered && exit_intent_modal_present()
      dont_leave_triggered = true
      new DontLeaveModal().open()
    return
