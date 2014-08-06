HelloBar.SettingsStepRoute = Ember.Route.extend

  # Tells the sub-steps to use the model associated w/ it's parent step

  model: ->
    @modelFor('application')

  # Sets suto-forwarding on the parent step upon selection

  setupController: (controller, model) ->
    @_super(controller, model)

    parentRoute = @routeName.split('.')[0]
    @controllerFor(parentRoute).set('routeForwarding', @routeName)

  # Called whenever the application leaves this route. Used  here to 
  # deconsturct some things when the app transtitions to a parent step
  # due to the use of the back button

  deactivate: ->
    parentRoute = @routeName.split('.')[0]
    @controllerFor(parentRoute).set('routeForwarding', false)


#-----------  Setup Sub-Step Routes  -----------#

HelloBar.SettingsEmailsRoute   = HelloBar.SettingsStepRoute.extend()
HelloBar.SettingsSocialRoute   = HelloBar.SettingsStepRoute.extend()
HelloBar.SettingsClickRoute    = HelloBar.SettingsStepRoute.extend()
HelloBar.SettingsFeedbackRoute = HelloBar.SettingsStepRoute.extend()

HelloBar.StyleBarRoute         = HelloBar.SettingsStepRoute.extend()
HelloBar.StylePopupRoute       = HelloBar.SettingsStepRoute.extend()

HelloBar.TargetingLeavingRoute = HelloBar.SettingsStepRoute.extend()
HelloBar.TargetingScrollRoute  = HelloBar.SettingsStepRoute.extend()
HelloBar.TargetingDelayRoute   = HelloBar.SettingsStepRoute.extend()
