HelloBar.ToggleSwitchComponent = Ember.Component.extend

  classNames: ['toggle-switch']
  classNameBindings: ['switch:is-selected']
  attributeBindings: ['tabindex']

  #-----------  Trigger Changes  -----------#

  init: ->
    @_super()
    @on('change', @, @_elementValueDidChange)

  click: ->
    @_elementValueDidChange()

  #-----------  Persist Changes to Model  -----------#

  _elementValueDidChange: ->
    @toggleProperty('switch')