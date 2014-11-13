HelloBar.TextController = Ember.Controller.extend

  fontOptions: [
    {value: 'Helvetica,sans-serif', label: 'Helvetica'}
    {value: 'Arial,Helvetica,sans-serif', label: 'Arial'}
    {value: 'Georgia,serif', label: 'Georgia'}
    {value: 'Helvetica,Arial,sans-serif', label: 'Sans-Serif'}
  ]

  showThankYouText: (->
    @get("model.element_subtype") == "email"
  ).property("model.element_subtype")

  disableThankYouText: ( ->
    !@get("model.site.capabilities.custom_thank_you_text")
  ).property("model.site.capabilities.custom_thank_you_text")

  actions:
    openUpgradeModal: ->
      controller = this

      options =
        site: controller.get("model.site")
        successCallback: ->
          controller.set('model.site.capabilities', this.site.capabilities)
        upgradeBenefit: "customize your thank you text"
      new UpgradeAccountModal(options).open()

  #-----------  Step Settings  -----------#

  step: 4
  prevStep: 'colors'
  nextStep: 'targeting'
