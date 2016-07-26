HelloBar.InterstitialFacebookController = Ember.Controller.extend
  showFacebookUrl: false
  facebookLikeOptions: [
    {value: 'homepage', label: 'Home Page'}
    {value: 'use_location_for_url', label: 'Current Page Visitor is Viewing'}
    {value: 'other', label: 'Other'}
  ]

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

  setDefaults: ( ->
    return false unless @get('model')

    switch @get('interstitialType')
      when 'call'
        @set('model.headline', null)
        @set('model.link_text', null)
        @set('model.element_subtype', "call")
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
        @set('model.headline', "Like us on Facebook!")
        @set('model.element_subtype', "social/like_on_facebook")
  ).observes('model').on('init')

  inputIsInvalid: ( ->
    switch @get('interstitialType')
      when 'money'
        return Ember.isEmpty(@get('model.settings.url'))
        return Ember.isEmpty(@get('model.headline'))
        return Ember.isEmpty(@get('model.link_text'))
      when 'call'
        return Ember.isEmpty(@get('model.headline'))
        return Ember.isEmpty(@get('model.link_text'))
        return !isValidNumber(@get('controllers.application.phone_number'), @get('model.phone_country_code'))
      when 'contacts'
        return Ember.isEmpty(@get('model.headline'))
        return Ember.isEmpty(@get('model.link_text'))
      when 'facebook'
        if !@get('model.settings.use_location_for_url')
          return Ember.isEmpty(@get('model.settings.url_to_like'))
    false
  ).property('model.settings.url', 'model.link_text', 'model.headline', 'model.settings.url_to_like', 'model.settings.use_location_for_url', 'controllers.application.phone_number', 'model.phone_country_code')

