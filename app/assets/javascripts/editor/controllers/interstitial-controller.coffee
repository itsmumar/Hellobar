HelloBar.InterstitialController = Ember.Controller.extend

  needs: ['application']

  init: ->
    @_super.apply(this, arguments)

    switch @get('controllers.application.interstitialType')
      when 'money'
        @set('model.headline', "Check out our latest sale")
        @set('model.link_text', "Shop Now")
      when 'contacts'
        @set('model.headline', "Join our mailing list to stay up to date on our upcoming events")
        @set('model.link_text', "Subscribe")
      when 'facebook'
        @set('model.headline', "Like us on Facebook!")

  #-----------  Template Properties  -----------#

  showInterstitial: Ember.computed.alias('controllers.application.showInterstitial')
  interstitialType: Ember.computed.alias('controllers.application.interstitialType')

  actions:

    closeInterstitial: ->
      @set("controllers.application.showInterstitial", false)

    closeEditor: ->
      @get('controllers.application').send('closeEditor');
