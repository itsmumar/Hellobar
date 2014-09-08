HelloBar.TargetingController = Ember.Controller.extend

  ruleOptions: ( ->
    rules = @get("model.site.rules").map (rule) ->
      {id: rule.id, text: rule.name, description: rule.description}

    rules.push({id: 0, text: "Other...", description: "?"})
    rules
  ).property("model.site.rules")

  selectedRule: (->
    filtered = @get("ruleOptions").filter (rule) =>
      rule.id == @get("model.rule_id")

    filtered[0]
  ).property("model.rule_id", "model.site.rules")

  displayWhenOptions: [
    {value: 'immediately',   label: 'Show immediately'}
    {value: 'after_leaving', label: 'When a visitor is leaving'}
    {value: 'after_scroll',  label: 'After visitor scrolls'}
    {value: 'after_delay',   label: 'After a time delay'}
  ]

  setDefaultScrollType: ( ->
    if @get("model.display_when") == "after_scroll" && !@get("model.settings.display_when_scroll_type")
      @set("model.settings.display_when_scroll_type", "percentage")
  ).observes("model.display_when")

  setDefaultDelayUnits: ( ->
    if @get("model.display_when") == "after_delay" && !@get("model.settings.display_when_delay_units")
      @set("model.settings.display_when_delay_units", "seconds")
  ).observes("model.display_when")

  #-----------  Step Settings  -----------#

  step: 5
  prevStep: 'text'
  nextStep: false

  #-----------  Sub-Step Selection  -----------#

  # Sets a property which tells the route to forward to a previously
  # selected child route (ie. sub-step)

  routeForwarding: false

  changeTargeting: (->
    route = switch @get("model.display_when")
      when "after_leaving" then "targeting.leaving"
      when "after_scroll"  then "targeting.scroll"
      when "after_delay"   then "targeting.delay"
      else "targeting"

    @set('routeForwarding', false) if route == "targeting"
    @transitionToRoute(route)
  ).observes('model.display_when').on('init')
