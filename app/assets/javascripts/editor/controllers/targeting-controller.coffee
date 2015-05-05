HelloBar.TargetingController = Ember.Controller.extend

  canUseRuleModal: ( ->
    @get("model.site.capabilities.custom_targeted_bars")
  ).property("model.site.capabilities.custom_targeted_bars")

  ruleOptions: ( ->
    rules = @get("model.site.rules").slice()
    rules.push({name: "Other...", description: "?", editable: true})
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
    resetRuleDropdown: (ruleData = {}) ->
      if ruleData.id == undefined
        firstRule = @get('model.site.rules')[0]
        firstRule ||= { id: null }
        @set('model.rule_id', firstRule.id)

    openUpgradeModal: (ruleData = {}) ->
      controller = this
      controller.send("resetRuleDropdown", ruleData)

      options =
        site: controller.get("model.site")
        successCallback: ->
          controller.set('model.site.capabilities', this.site.capabilities)
        upgradeBenefit: "create custom-targeted rules"
      new UpgradeAccountModal(options).open()

    openRuleModal: (ruleData) ->
      InternalTracking.track_current_person("Editor Flow", {step: "Edit Targeting", goal: @get("model.element_subtype"), style: @get("model.type")}) if trackEditorFlow
      return @send("openUpgradeModal", ruleData) unless @get("canUseRuleModal")

      ruleData.siteID = window.siteID
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
          controller.send("resetRuleDropdown", ruleData)

      new RuleModal(options).open()

  trackTargetView: (->
    InternalTracking.track_current_person("Editor Flow", {step: "Targeting Settings", goal: @get("model.element_subtype"), style: @get("model.type")}) if trackEditorFlow
  ).on('init')

  #-----------  Step Settings  -----------#

  step: 5
  prevStep: 'text'
  nextStep: false

  #-----------  Sub-Step Selection  -----------#

  # Sets a property which tells the route to forward to a previously
  # selected child route (ie. sub-step)

  routeForwarding: false
