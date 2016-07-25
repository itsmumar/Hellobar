HelloBar.HomeRoute = Ember.Route.extend

  # Auto-redirects the index/home route to the first step

  redirect: ->
    if HB_DATA.skipInterstitial
      @replaceWith("settings")
    else
      @replaceWith("interstitial")
