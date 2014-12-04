class @AccountPromptModal extends Modal

  modalName: "account-prompt"

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#account-prompt-modal-template").html())
    @$modal = $(@template())
    @$modal.appendTo($("body"))

    super(@$modal)

  open: ->
    @_rerouteErrors()
    super

  close: ->
    false

  _rerouteErrors: ->
    flash = $('.global-content .flash-block')

    if flash.length
      message = flash.text()
      flash.remove()
      @_displayErrors([message])

