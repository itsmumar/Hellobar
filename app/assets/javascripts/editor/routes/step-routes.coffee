HelloBar.StepRoute = Ember.Route.extend

  setupController: (controller, model) ->
    @_super()

    @controllerFor('application').setProperties
      isFullscreen : false
      currentStep  : controller.step
      prevRoute    : controller.prevStep
      nextRoute    : controller.nextStep

    @transitionTo(controller.routeForwarding) unless !controller.routeForwarding


HelloBar.StyleRoute     = HelloBar.StepRoute.extend()
HelloBar.ColorsRoute    = HelloBar.StepRoute.extend()
HelloBar.TextRoute      = HelloBar.StepRoute.extend()
HelloBar.TargetingRoute = HelloBar.StepRoute.extend()
HelloBar.SettingsRoute  = HelloBar.StepRoute.extend()