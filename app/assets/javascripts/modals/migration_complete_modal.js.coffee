class @MigrationCompleteModal extends Modal

  modalName: 'migration-complete'

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#migration-complete-modal-template").html())
    @$modal = $(@template({}))
    @$modal.appendTo($("body"))

    @_bindCloseButton()

    super(@$modal)

  _bindCloseButton: ->
    @$modal.find("a.button").click =>
      @close()
