HelloBar.InterstitialRoute = Ember.Route.extend
  model: ->
    @modelFor("application")

  renderTemplate: ->
    @render
      outlet: "interstitial" # render main interstitial template inside of "interstitial" outlet

  # Set sub-step forwarding on interstitial load
  setSettingsForwarding: (model) ->
    settings = @controllerFor("settings")
    
    if /^social/.test model.element_subtype
      settings.routeForwarding = "settings.social"
    else
      switch model.element_subtype
        when "call"
          settings.routeForwarding = "settings.call"
        when "email"
          settings.routeForwarding = "settings.emails"
        when "traffic"
          settings.routeForwarding = "settings.click"
        when "announcement"
          settings.routeForwarding = "settings.announcement"
        else
          settings.routeForwarding = false

NestedInterstitialRoute = HelloBar.InterstitialRoute.extend
  renderTemplate: ->
    @render
      into: "interstitial" # render sub-interstitial templates into main "interstitial" template

  setupController: (controller, model) ->
    @_super(controller, model)

    controller.setDefaults()
    @setSettingsForwarding(model)

    unless @ instanceof HelloBar.InterstitialIndexRoute
      $.ajax
        method: "POST"
        url: "/sites/#{siteID}/track_selected_goal"


HelloBar.InterstitialIndexRoute = NestedInterstitialRoute.extend()
HelloBar.InterstitialMoneyRoute = NestedInterstitialRoute.extend()
HelloBar.InterstitialContactsRoute = NestedInterstitialRoute.extend()
HelloBar.InterstitialCallRoute = NestedInterstitialRoute.extend()
HelloBar.InterstitialFacebookRoute = NestedInterstitialRoute.extend()