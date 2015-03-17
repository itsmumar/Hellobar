#= require jquery
#= require browser
#= require jquery_ujs

#= require_self

#= require zeropad.jquery
#= require jstz-1.0.4.min
#= require underscore
#= require moment

#= require colorpicker
#= require color_thief
#= require jquery_dropper

#= require handlebars
#= require handlebars_helpers

$ ->
  
  #-----------  Old IE Detection  -----------#

  if (bowser.msie && bowser.version <= 9)
    $('body').addClass('oldIE')