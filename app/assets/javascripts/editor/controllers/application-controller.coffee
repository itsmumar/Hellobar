HelloBar.ApplicationController = Ember.Controller.extend
  
  #-----------  Step Tracking  -----------#

  # Tracks global step tracking 
  # (primarily observed by the step-navigation component)

  prevRoute: null 
  nextRoute: null
  currentStep: false

  #-----------  Color Palette  -----------#

  # Generates color palette from screengrab
  # (primarily observed by the color-picker component)

  colorPalette: []

  #-----------  Modal Triggers  -----------#

  # Query params are managed by the controller (and no the router)
  # This defines the acceptable params and toggles the modal property 
  # used to trigger the modal visibility.

  queryParams: ['modal']
  modal: null

  toggleModal: (->
    @toggleProperty('isModal')
  ).observes('modal')


  #-----------  Element Preview  -----------#

  # Render the element in the preview pane whenever style-affecting attributes change

  renderPreview: ( ->
    previewElement = $.extend({}, @get("model"),
      template_name: @get("model.element_subtype") or "traffic"
      hide_destination: true
      open_in_new_window: false
      pushes_page_down: true
      remains_at_top: true
      wiggle_wait: 0
      tab_side: "right"
      thank_you_text: "Thank you for signing up!"
    )

    HB.render(previewElement)
  ).observes("model.element_subtype", "model.message", "model.link_text", "model.font", "model.background_color", "model.border_color", "model.button_color", "model.link_color", "model.text_color", "model.link_style", "model.size", "model.settings.buffer_message", "model.settings.buffer_url", "model.settings.collect_names", "model.settings.link_url", "model.settings.message_to_tweet", "model.settings.pinterest_description", "model.settings.pinterest_full_name", "model.settings.pinterest_image_url", "model.settings.pinterest_url", "model.settings.pinterest_user_url", "model.settings.twitter_handle", "model.settings.url", "model.settings.url_to_like", "model.settings.url_to_plus_one", "model.settings.url_to_share", "model.settings.url_to_tweet", "model.settings.use_location_for_url")

  #-----------  State Default & Actions  -----------#

  # Tracks global application states & catches actions
  # (primarily observed by the application-view)

  isMobile: false
  isFullscreen: false
  saveSubmitted: false

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
