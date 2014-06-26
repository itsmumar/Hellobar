HelloBar.SettingsController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 1
  prevStep: false
  nextStep: 'style'

  #-----------  Settings Selection  -----------#

  routeForwarding: false

  actions:

    changeSettings: ->
      @set('routeForwarding', false)
      @transitionToRoute('settings')
      false