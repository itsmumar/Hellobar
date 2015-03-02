HelloBar.StyleController = Ember.Controller.extend

  sizeOptions: [
    {value: 'large', label: 'Large - 50px height, 17px font'}
    {value: 'regular', label: 'Regular - 30px height, 14px font'}
  ]

  typeOptions: [
    {value: 'Bar', label: 'Bar'}
    {value: 'Slider', label: 'Slider'}
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
