HelloBar.StyleController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 2
  prevStep: 'settings'
  nextStep: 'colors'

  #-----------  Sub-Step Selection  -----------#

  routeForwarding: false

  actions:

    changeStyle: ->
      @set('routeForwarding', false)
      @transitionToRoute('settings')
      false  