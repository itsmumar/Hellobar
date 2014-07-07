HelloBar.StyleController = Ember.Controller.extend

  themeOptions: [
    {id: 1, text: 'Theme 1'}
    {id: 2, text: 'Theme 2'}
    {id: 3, text: 'Theme 3'}
  ]

  placementOptions: [
    {id: 1, text: 'Top'}
    {id: 2, text: 'Bottom'}
  ]

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
      @transitionToRoute('style')
      false

HelloBar.StyleBarController = HelloBar.StyleController.extend()
HelloBar.StylePopupController = HelloBar.StyleController.extend()
