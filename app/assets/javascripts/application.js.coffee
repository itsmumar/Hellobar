#= require jquery
#= require jquery_ujs
#= require bootstrap
#= require zeropad.jquery
#= require handlebars
#= require moment
#= require amcharts/amcharts
#= require amcharts/serial
#= require lib/url_params

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
#= require_self

$ ->

  # Reveal Blocks
  $('.reveal-wrapper').click () ->
    if $(@).hasClass('activated')
      $(@).removeClass('activated')
    else
      $('.reveal-wrapper.activated').removeClass('activated')
      $(@).addClass('activated')
