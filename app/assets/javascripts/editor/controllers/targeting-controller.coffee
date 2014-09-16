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
        close: ->
          # if we selected "Other...", reset the current rule to the first
          if ruleData.id == undefined
            firstRule = controller.get('model.site.rules')[0]
            firstRule ||= { id: null }
            controller.set('model.rule_id', firstRule.id)

      new RuleModal(options).open()

  #-----------  Step Settings  -----------#

  step: 5
  prevStep: 'text'
  nextStep: false

  #-----------  Sub-Step Selection  -----------#

  # Sets a property which tells the route to forward to a previously
  # selected child route (ie. sub-step)

  routeForwarding: false
