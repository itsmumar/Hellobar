HelloBar.ToggleSwitchComponent = Ember.Component.extend

  tagName: 'div'
  classNames: ['toggle-switch']
  classNameBindings: ['switch:is-selected']

  mouseDown: ->
    @toggleProperty('switch')