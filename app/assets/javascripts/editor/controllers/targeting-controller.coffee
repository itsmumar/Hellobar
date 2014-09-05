HelloBar.TargetingController = Ember.Controller.extend

  ruleOptions: ( ->
    rules = @get("model.site.rules").slice()
    rules.push({name: "Other...", description: "?"})
    rules
  ).property("model.site.rules")

  selectedRule: (->
    selectedRuleId = @get('model.rule_id')
    @get("ruleOptions").find (rule) -> rule.id == selectedRuleId
  ).property("model.rule_id", "model.site.rules")

  # TODO: move this into openRuleModal
  popNewRuleModal: (->
    @send('openRuleModal', {}) unless @get('model.rule_id')
  ).observes('model.rule_id')

  actions:
    openRuleModal: (ruleData) ->
      ruleData.siteId = window.siteID
      controller = this

      options =
        ruleData: ruleData
        successCallback: ->
          ruleData = this
          updatedRule = controller.get('model.site.rules').find (rule) -> rule.id == ruleData.id

          if updatedRule
            Ember.set(updatedRule, "conditions", ruleData.conditions)
            Ember.set(updatedRule, "description", ruleData.description)
            Ember.set(updatedRule, "name", ruleData.name)
            Ember.set(updatedRule, "match", ruleData.match)
            Ember.set(updatedRule, "priority", ruleData.priority)
          else # we created a new rule
            controller.get('model.site.rules').push(ruleData)

          controller.set('model.rule_id', ruleData.id)
          controller.notifyPropertyChange('model.site.rules')

      new RuleModal(options).open()

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
