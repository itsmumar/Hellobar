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
#= require imagesloaded

#= require handlebars
#= require handlebars_helpers

$ ->
  
  #-----------  Old IE Detection  -----------#

  if (bowser.msie && bowser.version <= 9)
    $('body').addClass('oldIE')

  # ------- Code to grab dominant color -----#
  console.log('Matt, look at vendor.js.coffee line 28')
  # image = $('.preview-image-for-colorpicker').get(0)
  # imagesLoaded(image, ->
  #   colorThief = new ColorThief()
  #   dominantColor = colorThief.getColor(image)
    
  #   # if r, g, and b are equal (gray/white), use the first palette color
  #   if dominantColor[0] == dominantColor[1] and dominantColor[1] == dominantColor[2]
  #     paletteColors = colorThief.getPalette(image)
  #     dominantColor = paletteColors[0]

  #   # console.log(dominantColor)
  # )
