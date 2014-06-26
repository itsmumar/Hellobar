HelloBar.StepRoute = Ember.Route.extend

  # Normally, you would set the model independantly on every route. 
  # In this case, however, since the model names folow the convention
  # of the step-route names, I'm obviscating it for all step routes
  
  model: ->
    model = @routeName[0].toUpperCase() + @routeName.slice(1) + "Model"
    HelloBar[model].create()

  # Updates the current step in the application controller. Currently
  # being used to keep the step navigation component tracking correctly.
  # Also auto-forwards to an appropriate sub-step route if one has been
  # chosen.

  setupController: (controller, model) ->
    @_super()

    @controllerFor('application').setProperties
      isFullscreen : false
      currentStep  : controller.step
      prevRoute    : controller.prevStep
      nextRoute    : controller.nextStep

    @transitionTo(controller.routeForwarding) unless !controller.routeForwarding


#-----------  Setup Step Routes  -----------#

HelloBar.SettingsRoute  = HelloBar.StepRoute.extend()
HelloBar.StyleRoute     = HelloBar.StepRoute.extend()
HelloBar.ColorsRoute    = HelloBar.StepRoute.extend()
HelloBar.TextRoute      = HelloBar.StepRoute.extend()
HelloBar.TargetingRoute = HelloBar.StepRoute.extend()
