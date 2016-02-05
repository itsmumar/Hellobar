HelloBar.TextController = Ember.Controller.extend

  fontOptions: [
    {value: "'Open Sans',sans-serif", label: 'Open Sans'}
    {value: 'Helvetica,sans-serif', label: 'Helvetica'}
    {value: 'Arial,Helvetica,sans-serif', label: 'Arial'}
    {value: 'Georgia,serif', label: 'Georgia'}
    {value: 'Helvetica,Arial,sans-serif', label: 'Sans-Serif'}
  ]

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

  refreshResponse1: ( ->
    @send('refreshResponse', 1)
  ).observes(
    "model.answer1response",
    "model.answer1caption",
    "model.answer1link_text"
  ).on("init")

  refreshResponse2: ( ->
    @send('refreshResponse', 2)
  ).observes(
    "model.answer2response",
    "model.answer2caption",
    "model.answer2link_text"
  ).on("init")

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
      for index, siteElement of HB.siteElementsOnPage
        setTimeout(@resetQuestion(siteElement), 500)

    showResponse1: ->
      for index, siteElement of HB.siteElementsOnPage
        setTimeout(@showResponse(siteElement, 1), 500)

    showResponse2: ->
      for index, siteElement of HB.siteElementsOnPage
        setTimeout(@showResponse(siteElement, 2), 500)

    refreshResponse: (idx) ->
      for index, se of HB.siteElementsOnPage
        if se && se.displayResponse
          se.currentHeadline().textContent = @get("model.answer"+idx+"response")
          current_caption_el = se.currentCaption()
          new_caption_text = @get("model.answer"+idx+"caption")
          if (current_caption_el)
            current_caption_el.textContent = new_caption_text
          if @get("model.answer"+idx+"link_text")
            se.w.contentWindow.document.querySelector('.hb-cta').textContent = @get("model.answer"+idx+"link_text")

  resetQuestion: (se) ->
    if (se && se.displayResponse)
      prop = @get('model.use_question')
      @set('model.use_question', !prop)
      @set('model.use_question', prop)

  showResponse: (se, idx) ->
    if (se && se.displayResponse)
      se.displayResponse(idx)
      @send('refreshResponse', idx)
