HelloBar.SettingsStepRoute = Ember.Route.extend

  # Tells the sub-steps to use the model associated w/ it's parent step

  model: ->
    @modelFor('application')

  # Sets auto-forwarding on the parent step upon selection

  setupController: (controller, model) ->
    @_super(controller, model)

    parentRoute = @routeName.split('.')[0]
    @controllerFor(parentRoute).set('routeForwarding', @routeName)


#-----------  Setup Sub-Step Routes  -----------#

HelloBar.SettingsEmailsRoute       = HelloBar.SettingsStepRoute.extend()
HelloBar.SettingsSocialRoute       = HelloBar.SettingsStepRoute.extend()
HelloBar.SettingsClickRoute        = HelloBar.SettingsStepRoute.extend()
HelloBar.SettingsCallRoute         = HelloBar.SettingsStepRoute.extend()
HelloBar.SettingsFeedbackRoute     = HelloBar.SettingsStepRoute.extend()
HelloBar.SettingsAnnouncementRoute = HelloBar.SettingsStepRoute.extend()

HelloBar.StyleBarRoute             = HelloBar.SettingsStepRoute.extend()
HelloBar.StyleModalRoute           = HelloBar.SettingsStepRoute.extend()
HelloBar.StyleSliderRoute          = HelloBar.SettingsStepRoute.extend()
HelloBar.StyleTakeoverRoute        = HelloBar.SettingsStepRoute.extend()

HelloBar.TargetingEveryoneRoute    = HelloBar.SettingsStepRoute.extend()
HelloBar.TargetingMobileRoute      = HelloBar.SettingsStepRoute.extend()
HelloBar.TargetingHomepageRoute    = HelloBar.SettingsStepRoute.extend()
HelloBar.TargetingCustomRoute      = HelloBar.SettingsStepRoute.extend()
HelloBar.TargetingSavedRoute       = HelloBar.SettingsStepRoute.extend()
