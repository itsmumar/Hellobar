class @UpdateGDPRSettingsPromtModal extends Modal
  modalName: "gdpr-prompt"

  constructor: (@options = {}) ->
    @template ?= Handlebars.compile($("#update-gdpr-settings-prompt-modal-template").html())

    @$modal ?= $(@template(@options))
    @$modal.appendTo($("body"))

    super(@$modal)
