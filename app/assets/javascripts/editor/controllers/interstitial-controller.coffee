HelloBar.InterstitialController = Ember.Controller.extend Ember.Evented,

  needs: ['application']

  showInterstitial: Ember.computed.alias('controllers.application.showInterstitial')
  interstitialType: Ember.computed.alias('controllers.application.interstitialType')

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
  ).observes('model', 'interstitialType')

  #-----------  Facebook Options  -----------#

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

  #-----------  Email Template Defaults  -----------#

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

  #-----------  Input Validation  -----------#

  inputIsInvalid: ( ->
    switch @get('interstitialType')
      when 'money'
        return Ember.isEmpty(@get('model.settings.url'))
        return Ember.isEmpty(@get('model.headline'))
        return Ember.isEmpty(@get('model.link_text'))
      when 'call'
        return Ember.isEmpty(@get('model.headline'))
        return Ember.isEmpty(@get('model.link_text'))
        return !isValidNumber(@get('controllers.application.phone_number'), @get('model.phone_country_code'));
      when 'contacts'
        return Ember.isEmpty(@get('model.headline'))
        return Ember.isEmpty(@get('model.link_text'))
      when 'facebook'
        if !@get('model.settings.use_location_for_url')
          return Ember.isEmpty(@get('model.settings.url_to_like'))
    false
  ).property('model.settings.url', 'model.link_text', 'model.headline', 'model.settings.url_to_like', 'model.settings.use_location_for_url', 'controllers.application.phone_number', 'model.phone_country_code')

  #-----------  Actions  -----------#

  actions:

    closeInterstitial: ->
      transitionToEditor = =>
        if @get("model.element_subtype") == "email"
          @transitionToRoute("settings.emails")
        else
          @transitionToRoute('style')
        @trigger('viewClosed')

      isContactGoal = Ember.isEqual(@get('interstitialType'), 'contacts')
      hasNoContactLists = @get("model.site.contact_lists").length == 0 && $(".contact-list-modal:visible").length == 0

      transitionToEditor()

    closeEditor: ->
      @setProperties(
        'interstitialType'         : null
        'model.element_subtype'    : null
        'model.headline'           : null
        'model.link_text'          : null
        'model.phone_country_code' : 'US'
      )
