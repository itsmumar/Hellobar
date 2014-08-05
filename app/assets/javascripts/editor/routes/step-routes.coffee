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
      isFullscreen : false
      currentStep  : controller.step
      prevRoute    : controller.prevStep
      nextRoute    : controller.nextStep

    @replaceWith(controller.routeForwarding) unless !controller.routeForwarding


#-----------  Setup Step Routes  -----------#

HelloBar.StyleRoute     = HelloBar.StepRoute.extend()
HelloBar.ColorsRoute    = HelloBar.StepRoute.extend()
HelloBar.TextRoute      = HelloBar.StepRoute.extend()
HelloBar.TargetingRoute = HelloBar.StepRoute.extend()
