HelloBar.SettingsController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  needs: ['application']
  cannotContinue: ( ->
    @set('controllers.application.cannotContinue', Ember.isEmpty(@get('model.element_subtype')))
  ).observes('model.element_subtype')

  step: 1
  prevStep: false
  nextStep: 'style'
  hasSideArrows: ( ->
      return (HB_EDITOR_VARIATION == 'navigation')
    ).property()

  #-----------  Sub-Step Selection  -----------#

  setSubtype: (->
    switch @get("routeForwarding")
      when "settings.emails"
        @set("model.element_subtype", "email")
      when "settings.click"
        @set("model.element_subtype", "traffic")
      when "settings.social"
        @set("model.element_subtype", null)
  ).observes('routeForwarding')

  # Sets a property which tells the route to forward to a previously
  # selected child route (ie. sub-step)

  routeForwarding: false

  setSubtype: (->
    switch @get('routeForwarding')
      when 'settings.emails'
        @set('model.element_subtype', 'email')
      when 'settings.click'
        @set('model.element_subtype', 'traffic')
      when 'settings.social'
        @set('model.element_subtype', null)
  ).observes('routeForwarding')

  actions:

    changeSettings: ->
      @set('routeForwarding', false)
      @transitionToRoute('settings')
      false
