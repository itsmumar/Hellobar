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
HelloBar.TargetingLeavingRoute     = HelloBar.SettingsStepRoute.extend()
HelloBar.TargetingScrollRoute      = HelloBar.SettingsStepRoute.extend()
HelloBar.TargetingDelayRoute       = HelloBar.SettingsStepRoute.extend()

# Switch controllers based upon Email Ingration UI test
HelloBar.SettingsEmailsRoute = HelloBar.SettingsStepRoute.extend

  controllerName: ->
    if (HB_EMAIL_INTEGRATION_TEST == 'variant')
      'settingsEmailsVariant'
    else
      'settingsEmails'

  renderTemplate: (controller, model) ->
    if (HB_EMAIL_INTEGRATION_TEST == 'variant')
      @render('settings/emails-variant', {
        model: model
        view: 'step'
      })
    else
      @render('settings/emails', {
        model: model
        view: 'step'
      })
