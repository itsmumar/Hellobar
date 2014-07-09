HelloBar.TargetingController = Ember.Controller.extend

  ruleOptions: ( ->
    rules = @get("model.site.rules").map (rule) ->
      {id: rule.id, text: rule.name, description: rule.conditions}

    rules.push({id: 0, text: "Other...", description: "?"})
    rules
  ).property()

  selectedRuleDescription: ( ->
    filtered = @get("ruleOptions").filter (x) =>
      x.id == @get("model.rule_id")

    filtered[0].description
  ).property("model.rule_id")

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
