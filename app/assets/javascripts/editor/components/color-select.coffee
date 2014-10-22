HelloBar.ColorSelectComponent = Ember.Component.extend

  classNames: ['color-select']
  classNameBindings: ['inFocus', 'isSelecting']

  inFocus: false
  isSelecting: false

  cssStyle: (->
    'background-color:#' + @get('color')
  ).property('color')

  #-----------  Hex/RGB Watcher  -----------#

  rgbWatcher: ( () ->
    Ember.run.throttle(@, @setHex, 150)
  ).observes('rVal', 'gVal', 'bVal')

  didInsertElement: ->
    @setRGB()

  #-----------  RGB Properties  -----------#

  rVal: (->
    @setRGB(1)
  ).property('color')

  gVal: (->
    @setRGB(2)
  ).property('color')

  bVal: (->
    @setRGB(3)
  ).property('color')

  #-----------  Hex/RGB Conversion  -----------#

  setRGB: (index = 1) ->
    hex = @get('color')
    shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i
    hex = hex.replace(shorthandRegex, (m, r, g, b) ->
      r + r + g + g + b + b
    )
    result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
    return if result then parseInt(result[index], 16) else 255

  setHex: ->
    r = parseInt(@get('rVal'))
    g = parseInt(@get('gVal'))
    b = parseInt(@get('bVal'))
    @set('color', ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1))

  #-----------  Wrap Eye-Dropper  -----------#

  # eyeDropper: ( () ->
  #   return $.fn.dropperredux({}) unless @get('isSelecting')

  #   $.fn.dropperredux
  #     selector: $('#hellobar-preview-container > img')
  #     clickCallback: (color) =>
  #       @set('color', color.rgbhex)
  # ).observes('isSelecting').on('didInsertElement')

  #-----------  Wrap Color Gradient  -----------#

  miniColors: ( () ->
    @$('.gradient-block').minicolors
      inline: true
      theme: 'default'
      defaultValue: @get('color')
      change: (hex, opacity) =>
        @set('color', hex.substring(1))
  ).on('didInsertElement')

  miniColorsListener: Ember.throttledObserver 'color', 1000, () ->
    @$('.gradient-block').minicolors('value', @get('color'))

  #-----------  Push 'Recent' Changes to Controller  -----------#

  updateRecent: ( () ->
    recent = @get('recentColors')

    recent.shiftObject() unless recent.length < 3
    recent.pushObject(@get('color'))

    @set('recentColors', recent)
  ).observes('color')

  #-----------  Component State Switching  -----------#

  actions:

    toggleFocus: ->
      if @get('inFocus')
        @set('inFocus', false)
        @set('isSelecting', false)
      else
        @set('inFocus', true)
        @sendAction()

    toggleSelecting: ->
      @toggleProperty('isSelecting')


#-----------  Color Preview Child Views  -----------#

HelloBar.ColorPreview = Ember.View.extend

  tagName: 'li'
  classNames: ['color-preview']
  attributeBindings: ['style']

  style: (->
    'background-color:#' + @get('color')
  ).property('color')

  mouseDown: ->
    @set('parentView.color', @color)
