HelloBar.PreviewController = Ember.Controller.extend

  needs: ['application']

  #-----------  Template Properties  -----------#
  
  isMobile      : Ember.computed.alias('controllers.application.isMobile')
  isPushed      : Ember.computed.alias('model.pushes_page_down')
  barSize       : Ember.computed.alias('model.size')
  barPosition   : Ember.computed.alias('model.placement')    
  elementType   : Ember.computed.alias('model.type')
  
  previewStyleString: ( ->
    if @get('isMobile')
      "background-image:url(#{@get('model.site_preview_image_mobile')})"
    else
      "background-image:url(#{@get('model.site_preview_image')})"
  ).property('isMobile', 'model.site_preview_image', 'model.site_preview_image_mobile')

  previewImageURL: ( ->
    if @get('isMobile')
      "#{@get('model.site_preview_image_mobile')}"
    else
      "#{@get('model.site_preview_image')}"
  ).property('isMobile', 'model.site_preview_image', 'model.site_preview_image_mobile')

  #-----------  Color Intelligence  -----------#

  colorPalette: Ember.computed.alias('controllers.application.colorPalette')
  
  setSiteColors: ( ->
    return false if @get('model.id') || window.elementToCopyID
    
    colorPalette = @get('colorPalette')
    dominantColor = @get('dominantColor')

    #----------- Primary Color  -----------#

    primaryColor = dominantColor
    
    for color in colorPalette
      if Math.abs(color[0] - color[1]) > 10 || Math.abs(color[1] - color[2]) > 10 || Math.abs(color[0] - color[2]) > 10
        primaryColor = color
        break

    @set('model.background_color', one.color(primaryColor).hex().replace('#',''))

    #----------- Other Colors  -----------#

    white = 'ffffff'

    if @brightness(primaryColor) < 0.5
      @setProperties
        'model.text_color'   : white
        'model.button_color' : white
        'model.link_color'   : one.color(primaryColor).hex().replace('#','')
    else
      colorPalette.sort (a, b) =>
        @brightness(a) - @brightness(b)

      @setProperties
        'model.text_color'   : one.color(colorPalette[0]).hex().replace('#','')
        'model.button_color' : one.color(colorPalette[0]).hex().replace('#','')
        'model.link_color'   : white
        
  ).observes('colorPalette')

  brightness: (color) ->
    rgb = Ember.copy(color)

    [0..2].forEach (i) ->
      val = rgb[i] / 255
      rgb[i] = if val < 0.03928 then val / 12.92 else Math.pow((val + 0.055) / 1.055, 2.4)
 
    return (0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2])
