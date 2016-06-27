HelloBar.TargetingSavedController = Ember.Controller.extend
  needs: "targeting"

  actions:

    openRuleModal: (ruleData) ->
      @get('controllers.targeting').send('openRuleModal', ruleData)
