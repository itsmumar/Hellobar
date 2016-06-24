$ ->
  exit_intent_triggered = false

  exit_intent_modal_present = ->
    $('#exit-intent-modal-template').length > 0

  mouse_leaves_top_of_screen = (e) ->
    e.offsetY - $(window).scrollTop() < 0

  # user moves mouse past the top of the screen (exit intent)
  $('body').on 'mouseleave', (e) ->
    if mouse_leaves_top_of_screen(e) && exit_intent_modal_present() && !exit_intent_triggered
      new ExitIntentModal({site: window.site}).open()
      user_id = $('#exit-intent-modal-template').data('user-id')
      url = '/users/' + user_id + '/update_exit_intent'
      $.ajax
        method: 'POST'
        url: url
      exit_intent_triggered = true
