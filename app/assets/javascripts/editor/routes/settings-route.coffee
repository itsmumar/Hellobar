HelloBar.SettingsRoute = HelloBar.StepRoute.extend

  setupController: (controller, model) ->
    if /^social/.test model.element_subtype
      controller.routeForwarding = "settings.social"
    else
      switch model.element_subtype
        when "email"
          controller.routeForwarding = "settings.emails"
        when "traffic"
          controller.routeForwarding = "settings.click"
        else
          controller.routeForwarding = false

    @_super(controller, model)