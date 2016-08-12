$ ->
  modal_triggered: false

  upgrade_suggest_modal_present = ->
    $('#upgrade-suggest-modal-template').length > 0

  if upgrade_suggest_modal_present() && !modal_triggered
    new UpgradeSuggestModal({site: window.site}).open()
    user_id = $('#upgrade-suggest-modal-template').data('user-id')
    url = '/users/' + user_id + '/update_upgrade_suggest'
    $.ajax
      method: 'POST'
      url: url
    modal_triggered = true
