HelloBar.ColorSelectComponent = Ember.Component.extend

  classNames: ['color-select']
  classNameBindings: ['inFocus', 'isSelecting']

  inFocus: false
  isSelecting: false

  cssStyle: (->
    'background-color:#' + @get('color')
  ).property('color')

  #-----------  Hex-to-RGB Conversion  -----------#

  rgbObject: (->
    hex = @get('color')
    shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i
    hex = hex.replace(shorthandRegex, (m, r, g, b) ->
      r + r + g + g + b + b
    )
    result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
    return {
        r: if result then parseInt(result[1], 16) else null
        g: if result then parseInt(result[2], 16) else null
        b: if result then parseInt(result[3], 16) else null
    }
  ).property('color')

  #-----------  Initialize Dropper  -----------#

  eyeDropper: ( () ->
    return $.fn.dropperredux({}) unless @get('isSelecting')

    $.fn.dropperredux
      selector: $('.preview-wrapper img')
      clickCallback: (color) =>
        @set('color', color.rgbhex)
  ).observes('isSelecting').on('didInsertElement')

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
