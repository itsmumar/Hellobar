HelloBar.InterstitialIndexController = Ember.Controller.extend
  needs: ["application"]

  global: ( ->
    window
  ).property()

  csrfToken: ( ->
    $("meta[name=csrf-token]").attr("content")
  ).property()

  afterModel: (() ->
    # default values are defined in DB schema (shema.rb); we remember them here
    @defaults =
      "model.headline": @model.headline
      "model.link_text": @model.link_text
      "model.element_subtype": @model.element_subtype
      "model.phone_country_code": @model.phone_country_code
  ).observes("model")

# Reset defaults when transitioning to interstitial index (called from intersitial-route on controller setup)
  setDefaults: ->
    return false unless @get("model")

    @setProperties(@defaults)
