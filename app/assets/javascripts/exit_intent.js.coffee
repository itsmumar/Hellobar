$ ->
  exit_intent_triggered = false

  exit_intent_modal_present = ->
    if $('#exit-intent-modal-template').length > 0
      true
    else
      false

  $('body').on 'mouseleave', (e) ->
    if e.offsetY - $(window).scrollTop() < 0 && !exit_intent_triggered && exit_intent_modal_present()
      new ExitIntentModal().open()
      user_id = $('#exit-intent-modal-template').data('user-id')
      url = '/users/' + user_id + '/update_exit_intent'
      $.ajax
        method: 'POST'
        url: url
      exit_intent_triggered = true
    return
