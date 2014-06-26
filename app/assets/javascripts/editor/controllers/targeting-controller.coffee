HelloBar.TargetingController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 5
  prevStep: 'text'
  nextStep: false

  #-----------  Targeting Settings  -----------#
   
  whoSelection: null
  whoOptions: [
    {id: 1, text: 'Everyone'}
    {id: 2, text: '/signup'}
    {id: 3, text: '/new'}
    {id: 4, text: '/new'}
    {id: 5, text: 'Only visitors on certain pages'}
    {id: 6, text: 'Only visitors during certain dates'}
    {id: 7, text: 'Other...'}
  ]

  whenSelection: null
  whenOptions: [
    {route: null,                text: 'Show immediately'}
    {route: 'targeting.leaving', text: 'When a visitor is leaving'}
    {route: 'targeting.scroll',  text: 'After visitor scrolls'}
    {route: 'targeting.delay',   text: 'After a time delay'}
  ]

  #-----------  Sub-Step Selection  -----------#

  # Sets a property which tells the route to forward to a previously
  # selected child route (ie. sub-step)

  routeForwarding: false

  changeTargeting: (->
    if @get('whenSelection.route')
      @set('routeForwarding', @get('whenSelection.route'))
      @transitionToRoute(@get('whenSelection.route'))
    else 
      @set('routeForwarding', false)
      @transitionToRoute('targeting')
  ).observes('whenSelection').on('init')