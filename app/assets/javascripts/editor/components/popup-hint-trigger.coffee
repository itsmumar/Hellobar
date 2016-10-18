HelloBar.PopupHintTriggerComponent = Ember.Component.extend

  classNames: ['popup-hint-trigger']

  hintIsVisible: false

  mouseEnter: ->
    @set('hintIsVisible', true)

  mouseLeave: ->
    @set('hintIsVisible', false)

