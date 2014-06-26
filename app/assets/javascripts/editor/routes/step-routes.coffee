HelloBar.StepRoute = Ember.Route.extend

  setupController: (controller, model) ->
    @_super()

    @controllerFor('application').setProperties
      currentStep : controller.step
      prevRoute   : controller.prevStep
      nextRoute   : controller.nextStep


HelloBar.SettingsRoute = HelloBar.StepRoute.extend()
HelloBar.StyleRoute = HelloBar.StepRoute.extend()
HelloBar.ColorsRoute = HelloBar.StepRoute.extend()
HelloBar.TextRoute = HelloBar.StepRoute.extend()
HelloBar.TargetingRoute = HelloBar.StepRoute.extend()