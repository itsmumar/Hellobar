HelloBar.ToggleSwitchComponent = Ember.Component.extend

  classNames: ['toggle-switch']
  classNameBindings: ['displayValue:is-selected']
  attributeBindings: ['tabindex']

  #-----------  Trigger Changes  -----------#

  init: ->
    @_setDisplayValue()
    @_super()
    @on('change', @, @_elementValueDidChange)

  click: ->
    @_elementValueDidChange()

  #-----------  Persist Changes to Model  -----------#

  _elementValueDidChange: ->
    @toggleProperty('switch')
    @_setDisplayValue()

  _setDisplayValue: ->
    @set('displayValue', if @get('inverted') then !@get('switch') else @get('switch'))
