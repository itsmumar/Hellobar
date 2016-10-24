HelloBar.InterstitialMoneyController = Ember.Controller.extend
  needs: ["application"]

  setDefaults: ->
    return false unless @get("model")

    @set("model.headline", "Check out our latest sale")
    @set("model.link_text", "Shop Now")
    @set("model.element_subtype", "traffic")

  inputIsInvalid: ( ->
    return !!(
      Ember.isEmpty(@get("model.headline")) ||
      Ember.isEmpty(@get("model.link_text")) ||
      Ember.isEmpty(@get("model.settings.url"))
    )
  ).property(
    "model.settings.url",
    "model.link_text",
    "model.headline"
  )

  actions:
    closeInterstitial: ->
      @transitionToRoute("style")
