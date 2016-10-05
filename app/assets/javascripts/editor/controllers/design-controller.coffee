HelloBar.DesignController = Ember.Controller.extend

  needs: ['application']

  #-----------  Step Settings  -----------#

  step: 3
  prevStep: 'style'
  nextStep: 'targeting'

  imagePlacementOptions: [
    { value: 'top', label: 'Top' }
    { value: 'bottom', label: 'Bottom' }
    { value: 'left', label: 'Left' }
    { value: 'right', label: 'Right' }
    { value: 'above-caption', label: 'Above Caption' }
    { value: 'below-caption', label: 'Below Caption' }
  ]

  #-------------- Helpers ----------------#

  isABar: Ember.computed.equal('model.type', 'Bar')

  allowImages: Ember.computed 'model.type', ->
    return this.get('model.type') != "Bar"

  themeWithImage: Ember.computed 'currentTheme.image_upload_id', ->
    !!@get('currentTheme.image_upload_id')

  useThemeImage: Ember.computed 'model.use_default_image', ->
    @get('model.use_default_image') && @get('themeWithImage')

  hasUserChosenImage: Ember.computed 'model.image_url', 'model.image_type', ->
    @get('model.image_url') && @get('model.image_type') != 'default'

  getImagePlacement: ->
    positionIsSelectable  = @get('currentTheme.image.position_selectable')
    imageIsbackground     = (@get('model.image_placement') == 'background')
    positionIsEmpty       = Ember.isEmpty(@get('model.image_placement'))

    if !positionIsSelectable
      @get('currentTheme.image.position_default')
    else if imageIsbackground || positionIsEmpty
      @get('currentTheme.image.position_default')
    else
      @get('model.image_placement')

  #----------- Theme Settings  -----------#

  themeOptions: availableThemes

  currentTheme: Ember.computed('model.theme_id', 'themeOptions', ->
    _.find(@get('themeOptions'), (theme) => theme.id == @get('model.theme_id'))
  )

  # Editor UI Properties
  imageUploadCopy         : Ember.computed.oneWay('currentTheme.image.upload_copy')
  showImagePlacementField : Ember.computed.oneWay('currentTheme.image.position_selectable')

  # Site Element Theme Properties
  themeChanged: Ember.observer('currentTheme', ->
    Ember.run.next(@, ->
      themeStyleDefaults = @get('currentTheme.defaults')[@get('model.type')] || {}

      _.each themeStyleDefaults, (value, key) =>
        @set("model.#{key}", value)

      @setProperties
        'model.image_placement'   : @getImagePlacement()
        'model.use_default_image' : false

      unless @get('hasUserChosenImage')
        if @get('themeWithImage')
          @setDefaultImage()
          @setProperties('model.use_default_image' : true)
        else
          @send('setImageProps', null, '')
    )
  )

  defaultImageToggled: ( ->
    if @get('useThemeImage') then @setDefaultImage()
  ).observes('model.use_default_image').on('init')

  setDefaultImage: ->
    imageID  = @get('currentTheme.image_upload_id')
    imageUrl = @get('currentTheme.image.default_url')
    @send('setImageProps', imageID, imageUrl, 'default')

  # Workaround for known Ember.Select issues: https://github.com/emberjs/ember.js/issues/4150
  emberSelectWorkaround: Ember.observer('currentTheme', ->
    @set('showImagePlacementField', false)
    Ember.run.next(@, ->
      @set('showImagePlacementField', @get('currentTheme.image.position_selectable'))
    )
  )

  #-----------  Text Settings  -----------#

  hideLinkText             : Ember.computed.match('model.element_subtype', /social|announcement/)
  showEmailPlaceholderText : Ember.computed.equal('model.element_subtype', 'email')
  showNamePlaceholderText  : Ember.computed('model.settings.fields_to_collect', () ->
    _.find(@get('model.settings.fields_to_collect'), (field) -> field.type == 'builtin-name').is_enabled
  )

  fontOptions: Ember.computed 'model.theme_id', ->
    foundTheme = _.find availableThemes, (theme) =>
      theme.id == @get('model.theme_id')

    if foundTheme && foundTheme.fonts
      _.map foundTheme.fonts, (fontId) ->
        _.find availableFonts, (font) ->
          font.id == fontId
    else
      availableFonts

  #-----------  Questions Settings  -----------#

  showQuestionFields: Ember.computed.equal('model.use_question', true)

  setQuestionDefaults: ( ->
    if (@get('model.use_question'))
      @set('model.question'        , @get('model.question_placeholder')) unless @get('model.question')
      @set('model.answer1'         , @get('model.answer1_placeholder')) unless @get('model.answer1')
      @set('model.answer2'         , @get('model.answer2_placeholder')) unless @get('model.answer2')
      @set('model.answer1response' , @get('model.answer1response_placeholder')) unless @get('model.answer1response')
      @set('model.answer2response' , @get('model.answer2response_placeholder')) unless @get('model.answer2response')
      @set('model.answer1link_text', @get('model.answer1link_text_placeholder')) unless @get('model.answer1link_text')
      @set('model.answer2link_text', @get('model.answer2link_text_placeholder')) unless @get('model.answer2link_text')
  ).observes('model.use_question').on('init')

  setHBCallbacks: ( ->
    # Listen for when question answers are pressed and change the question tabs
    HB.on "answerSelected", (choice) =>
      this.set('model.paneSelectedIndex', choice)
      this.set('paneSelection', (this.get('paneSelection') || 0) + 1)
      this.send('showResponse' + choice)
  ).on("init")

  #-----------  Color Tracking  -----------#

  recentColors : ['ffffff', 'ffffff', 'ffffff', 'ffffff']
  siteColors   : Ember.computed.alias('controllers.application.colorPalette')
  focusedColor : Ember.computed.alias('controllers.application.focusedColor')

  showAdditionalColors: Ember.computed.equal('model.type', 'Bar')

  trackColorView: (->
    InternalTracking.track_current_person("Editor Flow", {step: "Color Settings", goal: @get("model.element_subtype"), style: @get("model.type")}) if trackEditorFlow && !Ember.isEmpty(@get('model'))
  ).observes('model').on('init')

  #-----------  Analytics  -----------#

  trackTextView: (->
    if trackEditorFlow && !Ember.isEmpty(@get('model'))
      InternalTracking.track_current_person("Editor Flow", {step: "Content Settings", goal: @get("model.element_subtype"), style: @get("model.type")})
  ).observes('model').on('init')

  actions:

    eyeDropperSelected: ->
      type = @get('model.type')
      if type == 'Modal' || type == 'Takeover'
        @set('focusedColor', null)
      false

    openUpgradeModal: ->
      controller = this
      new UpgradeAccountModal(
        site: controller.get('model.site')
        upgradeBenefit: 'customize your thank you text'
        successCallback: ->
          controller.set('model.site.capabilities', this.site.capabilities)
      ).open()

    setImageProps: (imageID, imageUrl, imageType = null) ->
      @setProperties
        'model.active_image_id'   : imageID
        'model.image_placement'   : @getImagePlacement()
        'model.image_url'         : imageUrl
        'model.image_type'        : imageType

    showQuestion: ->
      HB.showResponse = null
      @get("controllers.application").renderPreview()

    showResponse1: ->
      HB.showResponse = 1
      @get("controllers.application").renderPreview()

    showResponse2: ->
      HB.showResponse = 2
      @get("controllers.application").renderPreview()
