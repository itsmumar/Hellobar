HelloBar.SettingsStepRoute = Ember.Route.extend

  setupController: (controller, model) ->
    @_super()

    parentRoute = @routeName.split('.')[0]
    @controllerFor(parentRoute).set('routeForwarding', @routeName)


HelloBar.SettingsEmailsRoute   = HelloBar.SettingsStepRoute.extend()
HelloBar.SettingsSocialRoute   = HelloBar.SettingsStepRoute.extend()
HelloBar.SettingsClickRoute    = HelloBar.SettingsStepRoute.extend()
HelloBar.SettingsFeedbackRoute = HelloBar.SettingsStepRoute.extend()

HelloBar.StyleBarRoute         = HelloBar.SettingsStepRoute.extend()
HelloBar.StylePopupRoute       = HelloBar.SettingsStepRoute.extend()
