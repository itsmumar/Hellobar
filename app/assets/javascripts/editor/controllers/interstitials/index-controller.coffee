HelloBar.InterstitialIndexController = Ember.Controller.extend
  needs: ["application"]

  global: ( ->
    window
  ).property()
  
  csrfToken: ( ->
    $("meta[name=csrf-token]").attr("content")
  ).property()

  # Reset defaults when transitioning to interstitial index (called from intersitial-route on controller setup)
  setDefaults: ->
    return false unless @get("model")
    
    @set("model.headline", null)
    @set("model.link_text", null)
    @set("model.element_subtype", null)
    @set("model.phone_country_code", "US")