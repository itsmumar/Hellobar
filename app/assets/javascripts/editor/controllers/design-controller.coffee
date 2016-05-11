HelloBar.DesignController = Ember.Controller.extend

  needs: ['application']

  #-------------- Helpers ----------------#

  # get currently selected theme
  # foundTheme = _.find availableThemes, (theme) =>
  #   theme.id == @get('model.theme_id')

  isABar: Ember.computed.equal('model.type', 'Bar')

  #----------- Theme Settings  -----------#

  themeOptions: availableThemes

  themeChanged: Ember.observer 'model.theme_id', ->
    @set('themeChangeCount', (@get('themeChangeCount') || 0) + 1)
    if @get('themeChangeCount') > 1
      @applyThemeDefaults()

  applyThemeDefaults: ->
    foundTheme = _.find availableThemes, (theme) =>
      theme.id == @get('model.theme_id')

    if foundTheme && foundTheme.defaults[@get('model.type')]
      _.each foundTheme.defaults[@get('model.type')], (value, key) =>
        @set("model.#{key}", value)

  #-----------  Text Settings  -----------#

  fontOptions: Ember.computed 'model.theme_id', ->
    foundTheme = _.find availableThemes, (theme) =>
      theme.id == @get('model.theme_id')

    if foundTheme && foundTheme.fonts
      _.map foundTheme.fonts, (fontId) ->
        _.find availableFonts, (font) ->
          font.id == fontId
    else
      availableFonts

  hideLinkText: Ember.computed.match('model.element_subtype', /social|announcement/)
  showEmailPlaceholderText: Ember.computed.equal('model.element_subtype', 'email')
  showNamePlaceholderText: Ember.computed.equal('model.settings.collect_names', 1)
  showImagePlacementField: Ember.computed.notEmpty('model.image_url')

  #-----------  Questions Settings  -----------#

  showQuestionFields: Ember.computed.equal('model.use_question', true)

  setQuestionDefaults: ( ->
    if (@get('model.use_question'))
      @set('model.question', @get('model.question_placeholder')) unless @get('model.question')
      @set('model.answer1', @get('model.answer1_placeholder')) unless @get('model.answer1')
      @set('model.answer2', @get('model.answer2_placeholder')) unless @get('model.answer2')
      @set('model.answer1response', @get('model.answer1response_placeholder')) unless @get('model.answer1response')
      @set('model.answer2response', @get('model.answer2response_placeholder')) unless @get('model.answer2response')
      @set('model.answer1link_text', @get('model.answer1link_text_placeholder')) unless @get('model.answer1link_text')
      @set('model.answer2link_text', @get('model.answer2link_text_placeholder')) unless @get('model.answer2link_text')
  ).observes(
    "model.use_question"
  ).on("init")

  setHBCallbacks: ( ->
    # Listen for when question answers are pressed and change the question tabs
    HB.on "answerSelected", (choice) =>
      this.set('model.paneSelectedIndex', choice)
      this.set('paneSelection', (this.get('paneSelection') || 0) + 1)
      this.send('showResponse' + choice)
  ).on("init")


  #-----------  Image Settings  -----------#

  allowImages: Ember.computed 'model.type', ->
    return this.get('model.type') != "Bar"

  imagePlacementOptions: [
    {value: 'top', label: 'Top'}
    {value: 'bottom', label: 'Bottom'}
    {value: 'left', label: 'Left'}
    {value: 'right', label: 'Right'}
    {value: 'above-caption', label: 'Above caption'}
    {value: 'below-caption', label: 'Below caption'}
  ]

  #-----------  Step Settings  -----------#

  step: 3
  prevStep: 'style'
  nextStep: 'targeting'

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

    setImageProps: (imageID, imageUrl) ->
      @set('model.active_image_id', imageID)
      @set('model.image_url', imageUrl)

    showQuestion: ->
      HB.showResponse = null
      @get("controllers.application").renderPreview()

    showResponse1: ->
      HB.showResponse = 1
      @get("controllers.application").renderPreview()

    showResponse2: ->
      HB.showResponse = 2
      @get("controllers.application").renderPreview()
