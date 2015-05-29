# jQuery Background Image Color Selection Plug-In
#
# Copyright 2015 Matt Manske
# Copyright 2010 Jean-Luc Delatre (a.k.a Favonius, a.k.a Kevembuangga)
# 
# [JLD] heavy refurbishing, even changing the API...
#
# Dual licensed under the MIT and GPL licenses:
# http://www.opensource.org/licenses/mit-license.php
# http://www.gnu.org/licenses/gpl.html

( ($) ->

  config         = {}
  image_data     = []
  dropper_image  = null
  dropper_canvas = null
  hover_spyglass = null
  canvas_failure = false

  defaults =
    clickCallback     : (color, evt) -> false
    mouseMoveCallback : (color, evt) -> false
    mouseOutCallback  : (color, evt) -> false
    selector          : $('#background-image')
    hover_size        : 12

  defaults.selector.length = 0

  #-----------  jQuery Function  -----------#

  $.fn.dropperTrios = (settings = {}) ->

    dropperAbort();

    config = $.extend({}, defaults, settings)
    
    $('body').append "'<div class='dropperTrios_spyglass' style='width:#{config.hoverwidth}px; height:#{config.hoverwidth}px; display:none'></div>"
    hover_spyglass = $('body').children().last()

    if config.selector && config.selector.length
      if config.selector[0].complete
        setupCanvas.call(config.selector[0])
      else
        @load(setupCanvas)

    return config.selector

  $.fn.dropperClean = () ->

    dropperAbort();

  #-----------  Abort Previous Instances  -----------#

  dropperAbort = () ->
    image_data = []

    if dropper_canvas
      $(dropper_canvas).remove()
      dropper_canvas = null

    if hover_spyglass
      $(hover_spyglass).remove()
      hover_spyglass = null

    config.selector = defaults.selector;

  #-----------  Setup Canvas  -----------#

  setupCanvas = () ->
    dropper_image = @

    dropper_canvas = document.createElement('canvas')
    dropper_canvas.width = $('.preview-image').width()
    dropper_canvas.height = $('.preview-image').height()

    $(dropper_canvas).insertBefore(@)

    try
      ctx = dropper_canvas.getContext('2d')
      drawImageCanvas(ctx, @)
      image_data = ctx.getImageData(0, 0, @width, @height)
    catch e
      canvas_failure = true
      dropperAbort()
      return

    bindEvents()

  #-----------  Mimic Background "Cover" Display  -----------#

  drawImageCanvas = (ctx, img) ->
    iw = img.width
    ih = img.height
    cw = ctx.canvas.width
    ch = ctx.canvas.height

    imgRatio = img.height / img.width
    ctxRatio = ctx.canvas.height / ctx.canvas.width

    if ctxRatio > imgRatio
      # Full Height, Cropped Width
      sx = sy = 0
      sWidth = img.height * (imgRatio)
      sHeight = img.height
      
      dx = dy = 0
      dWidth = ctx.canvas.width
      dHeight = ctx.canvas.height
    else
      # Full Width, Cropped Height
      sx = sy = 0
      sWidth = img.width
      sHeight = Math.round(img.height * imgRatio)

      dx = dy = 0
      dWidth = ctx.canvas.width
      dHeight = ctx.canvas.height

    ctx.drawImage(img, sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight)

  #-----------  Event Binding  -----------#
  
  bindEvents = () ->
    $(dropper_canvas)
      .mousemove(mouseMove)
      .mouseenter(mouseMove)
      .mouseleave(mouseLeave)
      .mousedown(mouseDown)

  unbindEvents = () ->
    $(dropper_canvas)
      .unbind('mousemove')
      .unbind('mouseleave')
      .unbind('mouseenter')
      .unbind('mousedown')

  #-----------  Mouse Events  -----------#

  mouseMove = (evt) ->
    canvas_index = canvasIndexFromEvent(evt, $(@))
    color = colorFromData(canvas_index)

    hover_spyglass.css(
      'top'              : evt.pageY - 15
      'left'             : evt.pageX + 10
      'background-color' : '#' + color.hex
      'position'         : 'absolute'
    ).show()

  mouseLeave = (evt) ->
    canvas_index = canvasIndexFromEvent(evt, $(@))
    color = colorFromData(canvas_index)

    hover_spyglass.hide()

  mouseDown = (evt) ->
    canvas_index = canvasIndexFromEvent(evt, $(@))
    color = colorFromData(canvas_index)

    config.clickCallback(color, evt)
    false

  #-----------  Helper Functions  -----------#

  colorFromData = (canvas_index) ->
    console.log canvas_index, image_data.data[canvas_index]

    color = 
      r: image_data.data[canvas_index]
      g: image_data.data[canvas_index + 1]
      b: image_data.data[canvas_index + 2]
      a: image_data.data[canvas_index + 3]
    color.hex = rgbToHex(color)
    
    return color

  canvasIndexFromEvent = (e, obj) ->
    x = e.pageX - parseInt(obj.offset().left)
    y = e.pageY - parseInt(obj.offset().top)
    
    return (x + y * obj.width()) * 4

  #-----------  Color Helpers  -----------#

  rgbToHex = (color) ->
    return toHex(color[0]) + toHex(color[1]) + toHex(color[2])

  toHex = (i) ->
    return 'ff' unless i

    str = i.toString(16)
    while str.length < 2
      str = '0' + str
 
    return str

) jQuery