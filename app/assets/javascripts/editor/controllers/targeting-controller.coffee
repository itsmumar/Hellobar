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

  triggerModal: (ruleData) ->
    controller = this
    ruleId = ruleData.id
    $form = $("form#rule-#{ruleId}")
    $modal = $form.parents('.modal-wrapper:first')

    ruleToUpdate = controller.get('model.site.rules').find (rule) ->
      rule.id == ruleData.id

    options =
      successCallback: ->
        ruleData = this
        # why dont newly created rules have conditions?

        ruleIds = controller.get('model.site.rules').map (rule) -> rule.id

        updatedRules = if ruleIds.contains(ruleData.id)
          controller.get('model.site.rules').map (rule) ->
            return rule unless rule.id == ruleData.id
            return ruleData
        else
          $form.find('.condition').remove() # remove any conditions
          $form.find('.form-control').val(null) # clear Rule Modal form values

          rules = controller.get('model.site.rules').map (rule) -> rule
          rules.push(ruleData)
          rules

        controller.set('model.site.rules', updatedRules)
        controller.set('model.rule_id', ruleData.id)

    new RuleModal($modal, options).open()

  popNewRuleModal: (->
    ruleId = @get('model.rule_id')

    if ruleId == 0
      @triggerModal({ id: ruleId })
  ).observes("model.rule_id")

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
