HelloBar.TargetingController = Ember.Controller.extend

  whoOptions: [
    {id: 1, text: 'Everyone'}
    {id: 2, text: '/signup'}
    {id: 3, text: '/new'}
    {id: 4, text: '/new'}
    {id: 5, text: 'Only visitors on certain pages'}
    {id: 6, text: 'Only visitors during certain dates'}
    {id: 7, text: 'Other...'}
  ]

  whenOptions: [
    {route: null,                text: 'Show immediately'}
    {route: 'targeting.leaving', text: 'When a visitor is leaving'}
    {route: 'targeting.scroll',  text: 'After visitor scrolls'}
    {route: 'targeting.delay',   text: 'After a time delay'}
  ]

  unitsOptions: [
    {id: 1, text: 'hours'}
    {id: 2, text: 'minuts'}
    {id: 3, text: 'seconds'}
  ]

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
