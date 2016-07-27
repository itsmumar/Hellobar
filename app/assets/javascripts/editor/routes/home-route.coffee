HelloBar.HomeRoute = Ember.Route.extend

  # Auto-redirects the index/home route to the first step
  redirect: ->
    if HB_DATA.skipInterstitial || localStorage["stashedEditorModel"]
      # skip interstitial if it's explisitly set in global variable or if editor model was already stored in localStorage
      @replaceWith("settings")
    else
      @replaceWith("interstitial")
