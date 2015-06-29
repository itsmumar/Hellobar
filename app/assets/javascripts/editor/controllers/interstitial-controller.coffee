HelloBar.InterstitialController = Ember.Controller.extend

  needs: ['application']

  facebookLikeOptions: [
    {value: 'homepage', label: 'Home Page'}
    {value: 'use_location_for_url', label: 'Current Page Visitor is Viewing'}
    {value: 'other', label: 'Other'}
  ]
  showFacebookUrl: false

  selectedFacebookLikeOptions: ( (key, value) ->
    if arguments.length > 1
      @set('showFacebookUrl', false)
      @set('model.settings.use_location_for_url', false)

      if value == 'homepage'
        @set('model.settings.url_to_like', @get('model.site.url'))
      else if value == 'use_location_for_url'
        @set('model.settings.use_location_for_url', true)
      else
        @set('showFacebookUrl', true)
      return value
    else
      'homepage'
  ).property()

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
        @createDefaultContactList()
      when 'facebook'
        @set('model.element_subtype', "social/like_on_facebook")
        @set('model.headline', "Like us on Facebook!")



  showInterstitial: Ember.computed.alias('controllers.application.showInterstitial')
  interstitialType: Ember.computed.alias('controllers.application.interstitialType')

  #-----------  Email template defaults  -----------#

  createDefaultContactList: ->
    if @get("model.site.contact_lists").length == 0 || @get("model.contact_list_id") == 0
      if @get("model.site.contact_lists").length > 0
        @set("model.contact_list_id", @get("model.site.contact_lists")[0].id)
      else
        $.ajax "/sites/#{@get('model.site.id')}/contact_lists.json",
          type: "POST"
          data: {contact_list: {name: "My Contacts", provider: 0, double_optin: 0}}
          success: (data) =>
            @set("model.site.contact_lists", [data])
            @set("model.contact_list_id", data.id)
          error: (response) =>
            # Failed to create default list.  Without a list set a user will see the ContactListModal

  #-----------  View actions  -----------#

  actions:

    closeInterstitial: ->
      choice = @get('controllers.application.interstitialType')

      # Trigger the transition to the category they made when they close the overlay
      map = {money: 'click', contacts: 'emails'}
      if map[choice]
        @get('controllers.application').send('transitionToRoute', "settings.#{map[choice]}")

      # Remove the view
      wrapper = $('.goal-interstitial')
      wrapper.addClass('transitioning')

      setTimeout ->
        wrapper.remove()
      , 1000

    closeEditor: ->
      @get('controllers.application').send('closeEditor')
