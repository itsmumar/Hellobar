HelloBar.ColorSelectComponent = Ember.Component.extend

  classNames: ['color-select']
  classNameBindings: ['inFocus', 'isSelecting']

  inFocus: false
  isSelecting: false

  cssStyle: (->
    'background-color:#' + @get('color')
  ).property('color')

  #-----------  RGB Observer  -----------#

  didInsertElement: ->
    @setRGB()

  setRGB: Ember.throttledObserver 'color', 75, ->
    rgb = @getRGB()

    @set 'rVal', parseInt(rgb[1], 16)
    @set 'gVal', parseInt(rgb[2], 16)
    @set 'bVal', parseInt(rgb[3], 16)

  #-----------  Hex/RGB Conversion  -----------#

  getRGB: () ->
    hex = @get('color')
    shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i
    hex = hex.replace(shorthandRegex, (m, r, g, b) ->
      r + r + g + g + b + b
    )
    result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
    result || ['ffffff', 'ff', 'ff', 'ff']

  setHex: Ember.debouncedObserver 'rVal', 'gVal', 'bVal', 150, ->
    r = parseInt(@get('rVal'))
    g = parseInt(@get('gVal'))
    b = parseInt(@get('bVal'))

    gradRGB = @get('rgb')
    inputRGB = {r: r, g: g, b: b} 

    unless JSON.stringify(gradRGB) == JSON.stringify(inputRGB) 
      hex = ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)
      @gradient.setHex('#' + hex)

  #-----------  Wrap Color Gradient  -----------#

  setupGradient: ( () ->
    obj = @

    ColorPicker.fixIndicators(
      obj.$('.slider-indicator')[0]
      obj.$('.gradient-indicator')[0]
    )

    @gradient = ColorPicker(
      obj.$('.slider')[0]
      obj.$('.gradient')[0]

      (hex, hsv, rgb, pickerCoordinate, sliderCoordinate) ->
        ColorPicker.positionIndicators(
          obj.$('.slider-indicator')[0],
          obj.$('.gradient-indicator')[0],
          sliderCoordinate
          pickerCoordinate
        );

        obj.set('color', hex.substring(1))
        obj.set('rgb', rgb)
    )

    @gradient.setHex('#' + @get('color'))
  ).on('didInsertElement')

  #-----------  Push 'Recent' Changes to Controller  -----------#

  updateRecent: Ember.debouncedObserver 'color', 75, ->
    color = @get('color')
    recent = @get('recentColors')

    unless recent.indexOf(color) > -1    
      recent.shiftObject()
      recent.pushObject(@get('color'))
      @set('recentColors', recent)

  #-----------  Screenshot Eye-Dropper  -----------#

  # eyeDropper: ( () ->
  #   return $.fn.dropperredux({}) unless @get('isSelecting')

  #   $.fn.dropperredux
  #     selector: $('#hellobar-preview-container > img')
  #     clickCallback: (color) =>
  #       @set('color', color.rgbhex)
  # ).observes('isSelecting').on('didInsertElement')

  #-----------  Component State Switching  -----------#

  actions:

    toggleFocus: ->
      @toggleProperty('inFocus')


#-----------  Color Preview Child Views  -----------#

HelloBar.ColorPreview = Ember.View.extend

  tagName: 'li'
  classNames: ['color-preview']
  attributeBindings: ['style']

  style: (->
    'background-color:#' + @get('color')
  ).property('color')

  mouseUp: ->
    @set('parentView.color', @color)
