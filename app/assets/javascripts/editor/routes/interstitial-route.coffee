HelloBar.InterstitialRoute = Ember.Route.extend
  model: ->
    @modelFor("application")

  renderTemplate: ->
    @render
      outlet: "interstitial" # render main interstitial template inside of "interstitial" outlet


NestedInterstitialRoute = HelloBar.InterstitialRoute.extend
  renderTemplate: ->
    @render
      into: "interstitial" # render sub-interstitial templates into main "interstitial" template

  setupController: (controller, model) ->
    @_super(controller, model)

    if controller.setDefaults
      controller.setDefaults()

    unless @ instanceof HelloBar.InterstitialIndexRoute
      $.ajax
        method: "POST"
        url: "/sites/#{siteID}/track_selected_goal"


HelloBar.InterstitialIndexRoute = NestedInterstitialRoute.extend()
HelloBar.InterstitialMoneyRoute = NestedInterstitialRoute.extend()
HelloBar.InterstitialContactsRoute = NestedInterstitialRoute.extend()
HelloBar.InterstitialCallRoute = NestedInterstitialRoute.extend()
HelloBar.InterstitialFacebookRoute = NestedInterstitialRoute.extend()