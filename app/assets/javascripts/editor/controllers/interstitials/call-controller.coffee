HelloBar.InterstitialCallController = Ember.Controller.extend
  needs: ["application"]

  setDefaults: ->
    return false unless @get("model")

    @set("model.headline", "Talk to us to find out more")
    @set("model.link_text", "Call Now")
    @set("model.element_subtype", "call")
    
  inputIsInvalid: ( ->
    return !!(
      Ember.isEmpty(@get("model.headline")) ||
      Ember.isEmpty(@get("model.link_text")) ||
      !isValidNumber(@get("controllers.application.phone_number"), @get("model.phone_country_code"))
    )
  ).property(
    "model.link_text",
    "model.headline",
    "controllers.application.phone_number",
    "model.phone_country_code"
  )

  actions:
    closeInterstitial: ->
      @transitionToRoute("style")