#= require jquery
#= require jquery_ujs
#= require bootstrap
#= require zeropad.jquery
#= require handlebars
#= require handlebars_helpers
#= require moment
#= require amcharts/amcharts
#= require amcharts/serial
#= require lib/url_params
#= require jstz-1.0.4.min

# Couldn't get 'require_tree .' to ignore the dashboard directory, so I opted to indivdually list the local js assets you needed here

#= require admin_metrics
#= require internal_tracking
#= require optimizely_tracking

#= require modal
#= require chart

#= require_tree ./modals
#= require_tree ./charts

#= require contact_lists
#= require summary
#= require improve
#= require sites_controller
#= require site_elements_controller
#= require upgrade_modal_initializer
#= require enforce_restrictions_initializer
#= require_self

$ ->

  # Reveal Blocks
  $('.reveal-wrapper').click (evt) ->
    unless $(@).hasClass('activated')
      $('.reveal-wrapper.activated').removeClass('activated')
      $(@).addClass('activated')

  # Detect User Timezone
  if $('#detect_timezone').length
    $timezone = $('#site_timezone, #user_timezone')
    userTimezone = jstz.determine().name()
    $timezone.val(userTimezone)

  # Remove Flash Messsages
  if $('.flash-block').length
    setTimeout ( ->
      $('.flash-block').addClass('show')
    ), 300

    $('.flash-block .icon-close').click (event) ->
      flash = $(event.currentTarget).parent('.flash-block')
      flash.removeClass('show')
      setTimeout ( ->
        flash.remove()
      ), 500
