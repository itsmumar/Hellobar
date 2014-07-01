HelloBar.ToggleSwitchComponent = Ember.Component.extend

  classNames: ['toggle-switch']
  classNameBindings: ['switch:is-selected']
  attributeBindings: ['tabindex']

  init: ->
    @_super()
    @on('change', @, @_elementValueDidChange)

  mouseDown: ->
    @_elementValueDidChange()

  _elementValueDidChange: ->
    console.log 'nong'
    @toggleProperty('switch')