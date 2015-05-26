HelloBar.PreviewView = Ember.View.extend

  classNames: ['preview-wrapper']

  colorPalette  : Ember.computed.alias('controller.colorPalette')
  dominantColor : Ember.computed.alias('controller.dominantColor')

  #-----------  Color Thief  -----------#

  formatRGB: (rgbArray) ->
    rgbArray.push(0)
    return rgbArray

  didInsertElement: ->
    colorThief = new ColorThief()
    image = $('.preview-image-for-colorpicker').get(0)
 
    imagesLoaded image, =>
      dominantColor = @formatRGB(colorThief.getColor(image))
      colorPalette = colorThief.getPalette(image, 4).map (color) => @formatRGB(color)

      @set('dominantColor', dominantColor)
      @set('colorPalette', colorPalette)
