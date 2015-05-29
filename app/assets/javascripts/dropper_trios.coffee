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

  config          = {}
  dropper_image   = null
  dropper_canvas  = null
  dropper_context = null
  hover_spyglass  = null
  canvas_failure  = false

  defaults =
    clickCallback     : (color, evt) -> false
    mouseMoveCallback : (color, evt) -> false
    mouseOutCallback  : (color, evt) -> false
    selector          : $('#background-image')
    hover_size        : 20

  defaults.selector.length = 0

  #-----------  jQuery Function  -----------#

  $.fn.dropperTrios = (settings = {}) ->

    dropperAbort();

    config = $.extend({}, defaults, settings)
    
    $('body').append "'<div class='dropperTrios_spyglass' style='width:#{config.hover_size}px; height:#{config.hover_size}px; display:none'></div>"
    hover_spyglass = $('.dropperTrios_spyglass')

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
      hover_spyglass.remove()
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
      dropper_context = dropper_canvas.getContext('2d')
      drawImageCanvas(dropper_context, @)
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
    color = colorFromData(evt)
    hover_spyglass.css(
      'top'              : evt.pageY - 25
      'left'             : evt.pageX - 25
      'background-color' : '#' + color
      'position'         : 'absolute'
    ).show()

  mouseLeave = (evt) ->
    hover_spyglass.hide()

  mouseDown = (evt) ->
    color = colorFromData(evt)
    config.clickCallback(color, evt)
    false

  #-----------  Helper Functions  -----------#

  colorFromData = (evt) ->
    pos = findPosition()
    x = evt.pageX - (pos.x)
    y = evt.pageY - (pos.y)
    coord = 'x=' + x + ', y=' + y
    p = dropper_context.getImageData(x, y, 1, 1).data
    color = ('000000' + rgbToHex(p[0], p[1], p[2])).slice(-6)

    return color

  #-----------  Color Helpers  -----------#

  findPosition = () ->
    obj = dropper_canvas
    cur_left = cur_top = 0

    if obj.offsetParent
      loop
        cur_left += obj.offsetLeft
        cur_top += obj.offsetTop
        unless obj = obj.offsetParent
          break
      return {x: cur_left, y: cur_top}
    return undefined

  rgbToHex = (r, g, b) ->
    if r > 255 || g > 255 || b > 255
      throw 'Invalid color component'

    return ((r << 16) | (g << 8) | b).toString(16)

) jQuery