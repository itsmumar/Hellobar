HelloBar.SettingsController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 1
  prevStep: false
  nextStep: 'style'

  #-----------  Sub-Step Selection  -----------#

  # Sets a property which tells the route to forward to a previously
  # selected child route (ie. sub-step)

  routeForwarding: false

  actions:

    changeSettings: ->
      @set('routeForwarding', false)
      @transitionToRoute('settings')
      false