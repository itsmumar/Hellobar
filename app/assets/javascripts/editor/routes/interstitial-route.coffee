HelloBar.InterstitialRoute = Ember.Route.extend
  renderTemplate: ->
    @render {
      outlet: "interstitial" # render main interstitial template inside of "interstitial" outlet
    }

NestedInterstitialRoute = HelloBar.InterstitialRoute.extend
  renderTemplate: ->
    @render {
      into: "interstitial" # render sub-interstitial templates into main "interstitial" template
    }

HelloBar.InterstitialIndexRoute = NestedInterstitialRoute.extend()
HelloBar.InterstitialPromoteRoute = NestedInterstitialRoute.extend()
HelloBar.InterstitialContactsRoute = NestedInterstitialRoute.extend()
HelloBar.InterstitialCallRoute = NestedInterstitialRoute.extend()
HelloBar.InterstitialFacebookRoute = NestedInterstitialRoute.extend()