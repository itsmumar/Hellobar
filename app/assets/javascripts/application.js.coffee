# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# compiled file.
#
# Read Sprockets README (https:#github.com/sstephenson/sprockets#sprockets-directives) for details
# about supported directives.
#
#= require jquery
#= require jquery_ujs
#= require bootstrap
#= require zeropad.jquery

# Couldn't get 'require_tree .' to ignore the dashboard directory, so I opted to indivdually list the local js assets you needed here

#= require admin_metrics
#= require internal_tracking
#= require optimizely_tracking
#= require modal
#= require_tree ./modals
#= require contact_lists
#= require rules
#= require_self

$ ->

  # Reveal Blocks
  $('.reveal-wrapper').click () ->
    if $(@).hasClass('activated')
      $(@).removeClass('activated')
    else
      $('.reveal-wrapper.activated').removeClass('activated')
      $(@).addClass('activated')

