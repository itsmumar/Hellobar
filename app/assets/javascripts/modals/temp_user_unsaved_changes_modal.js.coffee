class @TempUserUnsavedChangesModal extends Modal

  modalName: "temp-user-unsaved-changes"

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#temp-user-unsaved-changes-modal-template").html())
    @$modal = $(@template())
    @$modal.appendTo($("body"))

    super(@$modal)

  open: ->
    @_bindResumeButton(@$modal)
    super

  _bindResumeButton: (object) ->
    object.find("a.resume").click (e) =>
      @close()

  
