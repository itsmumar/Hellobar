HelloBar.TextController = Ember.Controller.extend

  needs: ['application']

  fontOptions: Ember.computed 'model.theme_id', ->
    foundTheme = _.find availableThemes, (theme) =>
      theme.id == @get('model.theme_id')

    if foundTheme && foundTheme.fonts
      _.map foundTheme.fonts, (fontId) ->
        _.find availableFonts, (font) ->
          font.id == fontId
    else
      availableFonts


  imagePlacementOptions: [
    {value: 'top', label: 'Top'}
    {value: 'bottom', label: 'Bottom'}
    {value: 'left', label: 'Left'}
    {value: 'right', label: 'Right'}
    {value: 'above-caption', label: 'Above caption'}
    {value: 'below-caption', label: 'Below caption'}
  ]

  hideNonBarFields: Ember.computed.equal('model.type', 'Bar')
  hideLinkText: Ember.computed.match('model.element_subtype', /social|announcement/)
  showEmailPlaceholderText: Ember.computed.equal('model.element_subtype', 'email')
  showNamePlaceholderText: Ember.computed.equal('model.settings.collect_names', 1)
  showImagePlacementField: Ember.computed.notEmpty('model.image_url')
  showQuestionFields: Ember.computed.equal('model.use_question', true)

  trackTextView: (->
    if trackEditorFlow && !Ember.isEmpty(@get('model'))
      InternalTracking.track_current_person("Editor Flow", {step: "Content Settings", goal: @get("model.element_subtype"), style: @get("model.type")})
  ).observes('model').on('init')

  setDefaults: ( ->
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
      this.set('paneSelected', choice)
      this.send('showResponse' + choice)
  ).on("init")

  #-----------  Step Settings  -----------#

  step: 4
  prevStep: 'colors'
  nextStep: 'targeting'

  #-----------  Actions  -----------#

  actions:

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
