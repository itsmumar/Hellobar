#= require jquery
#= require jquery_ujs
#= require jquery-ui.min
#= require handlebars
#= require serialize-json
#= require jstz-1.0.4.min

#= require flash_message_initializer
#= require modal
#= require modals/welcome_back_modal
#= require welcome_initializer


$ ->

  # Detect User Timezone
  if $('#detect_timezone').length
    $timezone = $('#site_timezone, #user_timezone')
    userTimezone = jstz.determine().name()
    $timezone.val(userTimezone)

  $(document).on 'click', '.clear-last-logged-in', (event) ->
    document.cookie = "login_email=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/"

  $(document).on 'click', '#not-you', (event) ->
    $('#user_email').val('') # clear the user email field
    $(this).remove()         # remove link from DOM
    return false
