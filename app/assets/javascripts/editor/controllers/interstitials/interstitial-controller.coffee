HelloBar.InterstitialController = Ember.Controller.extend
  needs: ['application']

  global: ( ->
    window
  ).property()
  
  csrfToken: ( ->
    $('meta[name="csrf-token"]').attr('content')
  ).property()

  setDefaults: ->
    return false unless @get("model")
    console.log("Setting defaults...")
    @set("model.headline", null)
    @set("model.link_text", null)
    @set("model.element_subtype", null)

  #-----------  Actions  -----------#

  actions:

    closeInterstitial: ->
      @transitionToRoute('style')
      #@trigger('viewClosed')

    closeEditor: ->
      @setProperties(
        'interstitialType'         : null
        'model.element_subtype'    : null
        'model.headline'           : null
        'model.link_text'          : null
        'model.phone_country_code' : 'US'
      )

#HelloBar.InterstitialIndexController = HelloBar.InterstitialController.extend()
#HelloBar.InterstitialCallController = HelloBar.InterstitialController.extend()