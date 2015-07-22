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
  ).observes("model.type", "model.element_subtype", "model.headline", "model.caption", "model.link_text", "model.font", "model.background_color", "model.border_color", "model.button_color", "model.link_color", "model.text_color", "model.link_style", "model.size", "model.closable", "model.show_branding", "model.settings.buffer_message", "model.settings.buffer_url", "model.settings.collect_names", "model.settings.link_url", "model.settings.message_to_tweet", "model.settings.pinterest_description", "model.settings.pinterest_full_name", "model.settings.pinterest_image_url", "model.settings.pinterest_url", "model.settings.pinterest_user_url", "model.settings.twitter_handle", "model.settings.url", "model.settings.url_to_like", "model.settings.url_to_plus_one", "model.settings.url_to_share", "model.settings.url_to_tweet", "model.settings.use_location_for_url", "model.pushes_page_down", "model.remains_at_top", "model.placement", "model.wiggle_button", "model.view_condition", "model.email_placeholder", "model.name_placeholder").on("init")

  renderPreviewWithAnimations: ( ->
    Ember.run.debounce(this, @doRenderPreview, true, 500)
  ).observes("model.animated").on("init")

  doRenderPreview: ( (withAnimations = false) ->
    previewElement = $.extend({}, @get("model"),
      template_name: @get("model.type").toLowerCase() + "_" + (@get("model.element_subtype") or "traffic")
      hide_destination: true
      open_in_new_window: @get("model.open_in_new_window")
      pushes_page_down: @get("model.pushes_page_down")
      remains_at_top: @get("model.remains_at_top")
      wiggle_button: @get("model.wiggle_button")
      animated: withAnimations && @get("model.animated")
      wiggle_wait: 0
      tab_side: "right"
      thank_you_text: "Thank you for signing up!"
      show_border: false
      size: @get("model.size"),
      primary_color: @get("model.background_color"),
      secondary_color: if @get("model.type") == "Bar" then @get("model.button_color") else @get("model.background_color")
    )

    HB.isPreviewMode = true
    HB.render(previewElement)
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
  ).observesBefore("model.type", "model.element_subtype", "model.headline", "model.caption", "model.link_text", "model.font", "model.background_color", "model.border_color", "model.button_color", "model.link_color", "model.text_color", "model.link_style", "model.size", "model.closable", "model.show_branding", "model.settings.url", "model.settings.buffer_message", "model.settings.buffer_url", "model.settings.collect_names", "model.settings.link_url", "model.settings.message_to_tweet", "model.settings.pinterest_description", "model.settings.pinterest_full_name", "model.settings.pinterest_image_url", "model.settings.pinterest_url", "model.settings.pinterest_user_url", "model.settings.twitter_handle", "model.settings.url", "model.settings.url_to_like", "model.settings.url_to_plus_one", "model.settings.url_to_share", "model.settings.url_to_tweet", "model.settings.use_location_for_url", "model.contact_list_id", "model.pushes_page_down", "model.remains_at_top", "model.animated", "model.placement", "model.wiggle_button", "model.email_placeholder", "model.name_placeholder")

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
