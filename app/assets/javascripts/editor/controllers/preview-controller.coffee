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

  colorPalette  : Ember.computed.alias('controllers.application.colorPalette')
  
  setSiteColors: ( ->
    return false if @get('model.id') || window.elementToCopyID
    
    colorPalette = @get('colorPalette')
    dominantColor = @get('dominantColor')

    # Primary Color

    primaryColor = dominantColor
    allColors = colorPalette.concat([dominantColor])
    
    for color in allColors
      if Math.abs(color[0] - color[1]) > 5 || Math.abs(color[1] - color[2]) > 5 || Math.abs(color[0] - color[2]) > 5
        primaryColor = color
        break

    @set('model.background_color', one.color(primaryColor).hex().replace('#',''))

    # Text Color

    # Button Color

    # Button Text

  ).observes('dominantColor', 'colorPalette')
