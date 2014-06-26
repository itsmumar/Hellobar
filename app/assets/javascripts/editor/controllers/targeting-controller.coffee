HelloBar.TargetingController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 5
  prevStep: 'text'
  nextStep: false

  #-----------  Sub-Step Selection  -----------#

  # Sets a property which tells the route to forward to a previously
  # selected child route (ie. sub-step)

  routeForwarding: false

  changeTargeting: (->
    if @get('content.whenSelection.route')
      @set('routeForwarding', @get('content.whenSelection.route'))
      @transitionToRoute(@get('content.whenSelection.route'))
    else 
      @set('routeForwarding', false)
      @transitionToRoute('targeting')
  ).observes('content.whenSelection').on('init')