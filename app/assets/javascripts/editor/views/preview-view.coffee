HelloBar.PreviewView = Ember.View.extend

  classNames: ['preview-wrapper']

  colorPalette  : Ember.computed.alias('controller.colorPalette')
  dominantColor : Ember.computed.alias('controller.dominantColor')

  #-----------  Color Thief  -----------#

  didInsertElement: ->
    colorThief = new ColorThief()
    image = $('.preview-image-for-colorpicker').get(0)
 
    imagesLoaded image, =>
      dominantColor = colorThief.getColor(image).push(0)
      colorPalette = colorThief.getPalette(image, 4).map (color) -> 
        color.push(0)
        return color

      @set('dominantColor', dominantColor)
      @set('colorPalette', colorPalette)
