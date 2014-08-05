HelloBar.StyleController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 2
  prevStep: 'settings'
  nextStep: 'colors'

  #-----------  Sub-Step Selection  -----------#

  # Sets a property which tells the route to forward to a previously
  # selected child route (ie. sub-step)

  routeForwarding: false

  actions:

    changeStyle: ->
      @set('routeForwarding', false)
      @replaceRoute('style')
      false

HelloBar.StyleBarController = HelloBar.StyleController.extend()
HelloBar.StylePopupController = HelloBar.StyleController.extend()
