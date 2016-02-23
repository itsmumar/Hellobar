#= require jquery
#= require jquery_ujs
#= require jquery-ui.min
#= require handlebars
#= require serialize-json
#= require jstz-1.0.4.min

#= require user_migration
#= require flash_message_initializer

$ ->
  # Detect User Timezone
  if $('#detect_timezone').length
    $timezone = $('#site_timezone, #user_timezone')
    userTimezone = jstz.determine().name()
    $timezone.val(userTimezone)
