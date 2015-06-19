HelloBar.InterstitialController = Ember.Controller.extend

  needs: ['application']

  init: ->
    @_super.apply(this, arguments)

    switch @get('controllers.application.interstitialType')
      when 'money'
        @set('model.headline', "Check out our latest sale")
        @set('model.link_text', "Shop Now")
        @set('model.element_subtype', "traffic")
      when 'contacts'
        @set('model.headline', "Join our mailing list to stay up to date on our upcoming events")
        @set('model.link_text', "Subscribe")
        @set('model.element_subtype', "email")
      when 'facebook'
        @set('model.element_subtype', "social/like_on_facebook")
        @set('model.headline', "Like us on Facebook!")

  #-----------  Template Properties  -----------#

  showInterstitial: Ember.computed.alias('controllers.application.showInterstitial')
  interstitialType: Ember.computed.alias('controllers.application.interstitialType')

  actions:

    closeInterstitial: ->
      choice = @get('controllers.application.interstitialType')
      @set("controllers.application.showInterstitial", false)

      # Trigger the transition to the category they made when they close the overlay
      map = {money: 'click', contacts: 'emails'}
      if map[choice]
        @get('controllers.application').send('transitionToRoute', "settings.#{map[choice]}")

    closeEditor: ->
      @get('controllers.application').send('closeEditor')
