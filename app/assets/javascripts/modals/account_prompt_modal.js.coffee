class @AccountPromptModal extends Modal

  modalName: "account-prompt"

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#account-prompt-modal-template").html())
    @$modal = $(@template())
    @$modal.appendTo($("body"))

    super(@$modal)

  close: ->
    false