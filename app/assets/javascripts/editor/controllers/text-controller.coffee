HelloBar.TextController = Ember.Controller.extend

  fontOptions: [
    {value: "'Open Sans',sans-serif", label: 'Open Sans'}
    {value: 'Helvetica,sans-serif', label: 'Helvetica'}
    {value: 'Arial,Helvetica,sans-serif', label: 'Arial'}
    {value: 'Georgia,serif', label: 'Georgia'}
    {value: 'Helvetica,Arial,sans-serif', label: 'Sans-Serif'}
  ]

  hideCaptionField: Ember.computed.equal('model.type', 'Bar')
  hideLinkText: Ember.computed.match('model.element_subtype', /social|announcement/)
  showThankYouText: Ember.computed.equal('model.element_subtype', 'email')
  disableThankYouText: Ember.computed.not('model.site.capabilities.custom_thank_you_text')

  trackTextView: (->
    if trackEditorFlow && !Ember.isEmpty(@get('model'))
      InternalTracking.track_current_person("Editor Flow", {step: "Content Settings", goal: @get("model.element_subtype"), style: @get("model.type")})
  ).observes('model').on('init')

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
