HelloBar.InterstitialContactsController = Ember.Controller.extend
  needs: ["application"]

  forceContacts: (HB_EMAIL_FLOW_TEST == "force")
  showEmailVolume: (HB_ONBOARDING_EMAIL_VOLUME == "messaging")

  monthlyPageviews: ( ->
    @get("model.site.monthly_pageviews") || 0
  ).property()

  formattedMonthlyPageviews: ( ->
    @get("monthlyPageviews").toLocaleString()
  ).property()

  hasEnoughSubscribers: ( ->
    @get("monthlyPageviews") > 1000
  ).property()

  calculatedSubscribers: ( ->
    Math.round(@get("monthlyPageviews") * 0.005)
  ).property()

  formattedCalculatedSubscribers: ( ->
    @get("calculatedSubscribers").toLocaleString()
  ).property()

  createDefaultContactList: ->
    if @get("model.site.contact_lists").length == 0 || @get("model.contact_list_id") == 0
      if @get("model.site.contact_lists").length > 0
        @set("model.contact_list_id", @get("model.site.contact_lists")[0].id)
      else
        $.ajax "/sites/#{@get("model.site.id")}/contact_lists.json",
          type: "POST"
          data: {contact_list: {name: "My Contacts", provider: 0, double_optin: 0}}
          success: (data) =>
            @set("model.site.contact_lists", [data])
            @set("model.contact_list_id", data.id)
          error: (response) =>
            # Failed to create default list.  Without a list set a user will see the ContactListModal

  setDefaults: ->
    return false unless @get("model")

    @set("model.headline", "Join our mailing list to stay up to date on our upcoming events")
    @set("model.link_text", "Subscribe")
    @set("model.element_subtype", "email")
    @createDefaultContactList()

  inputIsInvalid: ( ->
    return !!(
      Ember.isEmpty(@get("model.headline")) ||
      Ember.isEmpty(@get("model.link_text"))
    )
  ).property(
    "model.settings.url",
    "model.link_text",
    "model.headline",
    "model.settings.url_to_like",
    "model.settings.use_location_for_url",
    "controllers.application.phone_number",
    "model.phone_country_code"
  )

  actions:

    closeInterstitial: ->
      @transitionToRoute("settings.emails")
      #@trigger("viewClosed")
