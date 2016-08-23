HelloBar.InterstitialFacebookController = Ember.Controller.extend
  showFacebookUrl: false
  facebookLikeOptions: [
    {value: "homepage", label: "Home Page"}
    {value: "use_location_for_url", label: "Current Page Visitor is Viewing"}
    {value: "other", label: "Other"}
  ]

  selectedFacebookLikeOptions: ( (key, value) ->
    if arguments.length > 1
      @set("showFacebookUrl", false)
      @set("model.settings.use_location_for_url", false)

      if value == "homepage"
        @set("model.settings.url_to_like", @get("model.site.url"))
      else if value == "use_location_for_url"
        @set("model.settings.use_location_for_url", true)
      else
        @set("showFacebookUrl", true)
      return value
    else
      "homepage"
  ).property()

  setDefaults: ->
    return false unless @get("model")

    @set("model.headline", "Like us on Facebook!")
    @set("model.element_subtype", "social/like_on_facebook")

  inputIsInvalid: ( ->
    return !!(
      !@get("model.settings.use_location_for_url") &&
      Ember.isEmpty(@get("model.settings.url_to_like"))
    )
  ).property(
    "model.settings.use_location_for_url",
    "model.settings.url_to_like"
  )

  actions:
    closeInterstitial: ->
      @transitionToRoute("style")
