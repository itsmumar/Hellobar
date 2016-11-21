HelloBar.TargetingController = Ember.Controller.extend

  targetingUiVariant: (->
    window.targetingUiVariant
  ).property('model')

  trackTargetingView: (->
    if trackEditorFlow && !Ember.isEmpty(@get('model'))
      InternalTracking.track_current_person("Editor Flow", {step: "Targeting Step"})
  ).observes('model').on('init')

  #-------------- Helpers ----------------#

  defaultRules: ( ->
    rules = @get('model.site.rules').filter (rule) -> rule.editable == false
    rules.reduce (hash, rule) ->
        hash[rule.name]= rule
        hash
    , {}
  ).property()

  customRules: ( ->
    @get('model.site.rules').filter (rule) -> rule.editable == true
  ).property("model.site.rules")

  hasCustomRules: ( ->
    @get('customRules').length > 0
  ).property("model.site.rules")

  associateRuleToModel: (rule) ->
    @set('model.rule_id', rule && rule.id)
    @set('model.rule', rule)

  navigateRoute: (newRoute) ->
    @transitionToRoute(newRoute)
    @set('routeForwarding', newRoute)

  onSubRoute: (->
    (@get('routeForwarding') || "").split('.').length > 1
  ).property('routeForwarding')

  #-----------  Original UI Support  -----------#
  # remove these functions and all code paths where targetingUiVariant == false and/or fucntion names match *Original
  # if/when conclude the a/b test "Targeting UI Variation 2016-06-13" with 'variant'
  # revert this controller to the previous version if we conclude with 'original'

  trackUpgrade: ( ->
    InternalTracking.track_current_person("Editor Flow", {
                                                          step: "Choose Targeting Type - Converted to Pro",
                                                          ui: if @get('targetingUiVariant') then 'variant' else 'original'
                                                         })
  )

  canUseRuleModal: ( ->
    @get("model.site.capabilities.custom_targeted_bars")
  ).property("model.site.capabilities.custom_targeted_bars")

  popNewRuleModal: (->
    unless @get('targetingUiVariant') || @get('model.rule_id')
      @send('openRuleModalOriginal', {})
  ).observes('model.rule_id')

  showAfterConvertOptions: [
    {value: true, label: 'Continue showing even after the visitor responds'}
    {value: false, label: 'Stop showing after the visitor provides a response'}
  ]

  hideShowAfterConvertOptions: Ember.computed.equal('model.element_subtype', 'announcement')

  #-----------  New/Edit Rule Modal  -----------#

  canTarget: ( ->
    @get("model.site.capabilities.custom_targeted_bars")
  ).property("model.site.capabilities.custom_targeted_bars")

  ruleOptions: ( ->
    rules = @get("model.site.rules").slice().filter (rule) -> rule.editable == true
    rules.unshift({name: "Choose a saved rule...", description: "?", editable: true})
    rules
  ).property("model.site.rules")

  ruleOptionsOriginal: ( ->
    rules = @get("model.site.rules").slice()
    rules = rules.filter (rule) -> rule.name != "Mobile Visitors" && rule.name != "Homepage Visitors"
    rules.push({name: "Other...", description: "?", editable: true})
    rules
  ).property("model.site.rules")

  selectedRule: (->
    unless selectedRuleId = @get('model.rule_id')
      return null
    @get("ruleOptions").find (rule) -> rule.id == selectedRuleId
  ).property("model.rule_id", "model.site.rules")

  selectedRuleOriginal: (->
    selectedRuleId = @get('model.rule_id')
    @get("ruleOptionsOriginal").find (rule) -> rule.id == selectedRuleId
  ).property("model.rule_id", "model.site.rules")

  #-----------  Step Settings  -----------#

  step: 4
  prevStep: 'design'
  nextStep: false

  #-----------  Sub-Step Selection  -----------#

  # Sets a property which tells the route to forward to a previously
  # selected child-route/sub-step

  routeForwarding: false

  setRule: (->
    # return unless @get('targetingUiVariant') # Not sure why we are maintaining multiple version of UIs. Removing it.
    return if @get("showUpgradeModal")

    defaultRules = @get('defaultRules')
    customRules = @get('customRules')

    switch @get('routeForwarding')
      when 'targeting.everyone'
        @associateRuleToModel(defaultRules["Everyone"])
      when 'targeting.mobile'
        @associateRuleToModel(defaultRules["Mobile Visitors"])
      when 'targeting.homepage'
        @associateRuleToModel(defaultRules["Homepage Visitors"])
      when 'targeting.custom'
        @associateRuleToModel(null)
        @send('openRuleModal')
      when 'targeting.saved'
        unless @get('model.rule') in (rule for name, rule of customRules)
          @associateRuleToModel(null)
      else
        @associateRuleToModel(null)

    InternalTracking.track_current_person("Editor Flow", {step: "Choose Targeting Type", targeting: @get('routeForwarding')}) if trackEditorFlow
  ).observes('routeForwarding')

  showUpgradeModal: (->
    newRoute = @get('routeForwarding')

    if newRoute == 'targeting' || newRoute == 'targeting.everyone' || @get("canTarget")
      return false
    else
      InternalTracking.track_current_person("Editor Flow", {
                                                            step: "Choose Targeting Type - Upgrade Modal",
                                                            targeting: newRoute
                                                           })
      @send("openUpgradeModal", newRoute)
      return true
  ).property('routeForwarding')

  afterModel: (->
    cookieSettings = @get('model.settings.cookie_settings')
    if _.isEmpty(cookieSettings)
      cookieSettings = {
        duration: 0,
        success_duration: 0
      }

      @set('model.settings.cookie_settings', cookieSettings)
  ).observes('model')

  #-----------  Actions  -----------#

  actions:

    resetRuleDropdown: (ruleData = {}) ->
      if ruleData.id == undefined
        @associateRuleToModel(null)
        @navigateRoute('targeting')
      else
        @associateRuleToModel(ruleData)
        @navigateRoute('targeting.saved')

    openUpgradeModal: (successRoute = "targeting") ->
      controller = this
      controller.send("resetRuleDropdown")

      options =
        site: controller.get("model.site")
        successCallback: ->
          controller.set('model.site.capabilities', this.site.capabilities)
          controller.send("trackUpgrade")
          controller.send("navigateRoute", successRoute)
        upgradeBenefit: "create custom-targeted rules"
      new UpgradeAccountModal(options).open()

    openRuleModal: (ruleData = {}) ->
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

          controller.send("associateRuleToModel", ruleData)
          controller.notifyPropertyChange('model.site.rules')
        close: ->
          controller.send("resetRuleDropdown", ruleData)

      new RuleModal(options).open()

    # remove resetRuleDropdownOriginal, openRuleModalOriginal and openUpgradeModalOriginal
    # if/when conclude the a/b test "Targeting UI Variation 2016-06-13" with 'variant'
    # revert this controller to the previous version if we conclude with 'original'

    resetRuleDropdownOriginal: (ruleData = {}) ->
      if ruleData.id == undefined
        firstRule = @get('model.site.rules')[0]
        firstRule ||= { id: null }
        @set('model.rule_id', firstRule.id)

    openRuleModalOriginal: (ruleData) ->
      InternalTracking.track_current_person("Editor Flow", {step: "Edit Targeting", goal: @get("model.element_subtype"), style: @get("model.type")}) if trackEditorFlow
      return @send("openUpgradeModalOriginal", ruleData) unless @get("canUseRuleModal")

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
          controller.send("resetRuleDropdownOriginal", ruleData)

      new RuleModal(options).open()

    openUpgradeModalOriginal: (ruleData = {}) ->
      controller = this
      controller.send("resetRuleDropdownOriginal", ruleData)

      options =
        site: controller.get("model.site")
        successCallback: ->
          controller.set('model.site.capabilities', this.site.capabilities)
          controller.send("trackUpgrade")
        upgradeBenefit: "create custom-targeted rules"
      new UpgradeAccountModal(options).open()
