HelloBar.PreviewView = Ember.View.extend

  classNames: ['preview-wrapper']

  #-----------  Color Thief  -----------#

  formatRGB: (rgbArray) ->
    rgbArray.push(1)
    return rgbArray

  didInsertElement: ->
    colorThief = new ColorThief()
    image = $('.preview-image-for-colorpicker').get(0)

    imagesLoaded image, =>
      dominantColor = @formatRGB(colorThief.getColor(image))
      colorPalette = colorThief.getPalette(image, 4).map (color) => @formatRGB(color)

      @set('controller.dominantColor', dominantColor)
      @set('controller.colorPalette', colorPalette)
