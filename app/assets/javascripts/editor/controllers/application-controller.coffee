HelloBar.ApplicationController = Ember.Controller.extend

  #-----------  User  -----------#

  currentUser: ( -> window.currentUser ).property()
  isTemporaryUser: ( -> @get('currentUser') and @get('currentUser').status is 'temporary' ).property('currentUser')

  #-----------  Step Tracking  -----------#

  # Tracks global step tracking
  # (primarily observed by the step-navigation component)

  prevRoute: null
  nextRoute: null
  currentStep: false
  cannotContinue: true
  showInterstitial: false
  interstitialType: null

  #-----------  Color Palette  -----------#

  # Generates color palette from screengrab
  # (primarily observed by the color-picker component)

  colorPalette: []
  focusedColor: null

  #-----------  Element Preview  -----------#

  # Render the element in the preview pane whenever style-affecting attributes change

  renderPreview: ( ->
    Ember.run.debounce(this, @doRenderPreview, 500)
  ).observes(
    "model.use_question",
    "model.answer1",
    "model.answer2",
    "model.answer1response",
    "model.answer1caption",
    "model.answer1link_text",
    "model.answer2response",
    "model.answer2caption",
    "model.answer2link_text",
    "model.background_color",
    "model.border_color",
    "model.button_color",
    "model.caption",
    "model.closable",
    "model.element_subtype",
    "model.email_placeholder",
    "model.font",
    "model.headline",
    "model.image_placement",
    "model.image_url",
    "model.link_color",
    "model.link_style",
    "model.link_text",
    "model.name_placeholder",
    "model.placement",
    "model.pushes_page_down",
    "model.question",
    "model.remains_at_top",
    "model.phone_number",
    "model.settings.buffer_message",
    "model.settings.buffer_url",
    "model.settings.collect_names",
    "model.settings.link_url",
    "model.settings.message_to_tweet",
    "model.settings.pinterest_description",
    "model.settings.pinterest_full_name",
    "model.settings.pinterest_image_url",
    "model.settings.pinterest_url",
    "model.settings.pinterest_user_url",
    "model.settings.twitter_handle",
    "model.settings.url_to_like",
    "model.settings.url_to_plus_one",
    "model.settings.url_to_share",
    "model.settings.url_to_tweet",
    "model.settings.url",
    "model.settings.use_location_for_url",
    "model.show_branding",
    "model.size",
    "model.text_color",
    "model.type",
    "model.view_condition",
    "model.wiggle_button"
  ).on("init")

  renderPreviewWithAnimations: ( ->
    Ember.run.debounce(this, @doRenderPreview, true, 500)
  ).observes("model.animated").on("init")

  doRenderPreview: ( (withAnimations = false) ->
    previewElement = $.extend({}, @get("model"),
      animated: withAnimations && @get("model.animated")
      hide_destination: true
      open_in_new_window: @get("model.open_in_new_window")
      primary_color: @get("model.background_color"),
      pushes_page_down: @get("model.pushes_page_down")
      remains_at_top: @get("model.remains_at_top")
      secondary_color: if @get("model.type") == "Bar" then @get("model.button_color") else @get("model.background_color")
      show_border: false
      size: @get("model.size"),
      subtype: @get("model.element_subtype")
      tab_side: "right"
      template_name: @get("model.type").toLowerCase() + "_" + (@get("model.element_subtype") or "traffic")
      thank_you_text: "Thank you for signing up!"
      wiggle_button: @get("model.wiggle_button")
      wiggle_wait: 0
    )

    HB.isPreviewMode = true
    HB.removeAllSiteElements()
    HB.addToPage(HB.createSiteElement(previewElement))
    HB.isMobileWidth = "changed"
  )

  # Sets a callback on the preview script to rerender the preview after the user
  # closes the element
  setRerenderOnClose: ( ->
    that = this
    callback = ->
      delayedFunc = -> Ember.run.debounce(that, that.doRenderPreview, false, 500)
      setTimeout delayedFunc, 1000

    HB.on("elementDismissed", callback)
  ).on('init')

  #-----------  State Default  -----------#

  # Tracks global application states & catches actions
  # (primarily observed by the application-view)

  queryParams: ['rule_id']
  isMobile: false
  isFullscreen: false
  saveSubmitted: false
  modelIsDirty: false
  rule_id: null

  doneButtonText: (->
    "Save & Publish"
  ).property()

  setRuleID: (->
    @set("model.rule_id", parseInt(@get("rule_id")))
  ).observes("rule_id")

  # Model properties are all updated when the model is initially loaded, but we only want to set this flag on any property changes
  # that happen AFTER that initialization. By using an observesBefore here and only setting the flag if the property being changed
  # is not null or undefined before the change, we avoid setting the flag until the property has had an initial value set.

  setModelIsDirty: ( (obj, keyName) ->
    @set("modelIsDirty", true) if !!@get(keyName)
  ).observesBefore(
    "model.use_question",
    "model.answer1",
    "model.answer1response",
    "model.answer1caption",
    "model.answer1link_text",
    "model.answer2",
    "model.answer2response",
    "model.answer2caption",
    "model.answer2link_text",
    "model.animated",
    "model.background_color",
    "model.border_color",
    "model.button_color",
    "model.caption",
    "model.closable",
    "model.contact_list_id",
    "model.element_subtype",
    "model.email_placeholder",
    "model.font",
    "model.headline",
    "model.image_placement",
    "model.image_url",
    "model.link_color",
    "model.link_style",
    "model.link_text",
    "model.name_placeholder"
    "model.placement",
    "model.pushes_page_down",
    "model.question",
    "model.remains_at_top",
    "model.phone_number",
    "model.settings.buffer_message",
    "model.settings.buffer_url",
    "model.settings.collect_names",
    "model.settings.link_url",
    "model.settings.message_to_tweet",
    "model.settings.pinterest_description",
    "model.settings.pinterest_full_name",
    "model.settings.pinterest_image_url",
    "model.settings.pinterest_url",
    "model.settings.pinterest_user_url",
    "model.settings.redirect_url",
    "model.settings.redirect",
    "model.settings.twitter_handle",
    "model.settings.url_to_like",
    "model.settings.url_to_plus_one",
    "model.settings.url_to_share",
    "model.settings.url_to_tweet",
    "model.settings.url",
    "model.settings.use_location_for_url",
    "model.show_branding",
    "model.size",
    "model.text_color",
    "model.type",
    "model.wiggle_button"
  )

  #-----------  Actions  -----------#

  actions:

    toggleFullscreen: ->
      @toggleProperty('isFullscreen')
      false

    toggleMobile: ->
      @toggleProperty('isMobile')
      false

    toggleModal: ->
      @set('modal', null)
      false

    saveSiteElement: ->
      @toggleProperty('saveSubmitted')
      true

    closeEditor: ->
      if @get('isTemporaryUser')
        new TempUserUnsavedChangesModal().open()
      else
        dashboardURL = "/sites/#{window.siteID}/site_elements"

        if @get("modelIsDirty")
          options =
            dashboardURL: dashboardURL
            doSave: =>
              @send("saveSiteElement")

          new UnsavedChangesModal(options).open()
        else
          window.location = dashboardURL
