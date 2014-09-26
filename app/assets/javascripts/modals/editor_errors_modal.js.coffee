class @EditorErrorsModal extends Modal

  modalName: 'editor-errors'

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#editor-errors-modal-template").html())
    @$modal = $(@template({errors: @options.errors}))
    @$modal.appendTo($("body"))

    super(@$modal)
