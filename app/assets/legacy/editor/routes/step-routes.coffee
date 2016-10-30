HelloBar.StepRoute = Ember.Route.extend

# All step routes simply use the model loaded the the ApplicationRoute

  model: ->
    @modelFor('application')

# Updates the current step in the application controller. Currently
# being used to keep the step navigation component tracking correctly.
# Also auto-forwards to an appropriate sub-step route if one has been
# chosen.

  setupController: (controller, model) ->
    @_super(controller, model)

    @controllerFor('application').setProperties
      isFullscreen: false
      currentStep: controller.step
      prevRoute: controller.prevStep
      nextRoute: controller.nextStep

    if controller.routeForwarding
      @replaceWith(controller.routeForwarding)

  actions: {
    didTransition: (t) ->
      model = @model()
      currentRoute = @controllerFor("application").get("currentRouteName")
      # redirect to interstitial to select a goal after a page refresh unless it's rememebered in model
      # currentRoute==undefined indicates page refresh
      if !(currentRoute or HB_DATA.skipInterstitial or model.element_subtype)
        @replaceWith("interstitial")

      # TODO create more generic solution after refactoring to a newer Ember
      newRoute = @routeName

      if ((not newRoute) or (newRoute.indexOf('style') != 0))
        HelloBar.bus.trigger('hellobar.core.rightPane.hide')
  }



#-----------  Setup Step Routes  -----------#

HelloBar.StyleRoute = HelloBar.StepRoute.extend()
HelloBar.DesignRoute = HelloBar.StepRoute.extend()
HelloBar.TargetingRoute = HelloBar.StepRoute.extend()
HelloBar.SettingsRoute = HelloBar.StepRoute.extend()

HelloBar.TextRoute = HelloBar.StepRoute.extend
# A hack to ensure the preview is in sync with the question tabs
  setupController: (controller, model) ->
    @_super(controller, model)
    if model.use_question
      controller.send('showQuestion')
