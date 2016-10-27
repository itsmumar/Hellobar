class @ConfirmModal extends Modal

  modalName: "confirm"

  constructor: (@options = {}) ->
    @setDefaults()
    @template ?= Handlebars.compile($("#confirm-modal-template").html())

    @$modal ?= $(@template(@options))
    @$modal.appendTo(document.body)

    @_bindEvents()

    super(@$modal)

  setDefaults: ->
    @options.title ||= "Confirm action"
    @options.text ||= "Are you sure?"
    @options.confirmBtnText ||= "Confirm"
    @options.cancelBtnText ||= "Cancel"
    @options.showCloseIcon ||= false

  _bindEvents: ->
    @$modal.find(".confirm").click (evt) =>
      @options.confirm && @options.confirm()
      evt.preventDefault()

  close: ->
    @options.cancel && @options.cancel()
    super