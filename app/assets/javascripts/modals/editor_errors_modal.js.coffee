class @EditorErrorsModal extends Modal
  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#editor-errors-modal-template").html())
    @$modal = $(@template({errors: @options.errors}))
    @$modal.appendTo($("body"))

    super(@$modal)

  close: ->
    @$modal.remove()
