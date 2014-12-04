class @UnsavedChangesModal extends Modal

  modalName: "unsaved-changes"

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#unsaved-changes-modal-template").html())
    @$modal = $(@template())
    @$modal.appendTo($("body"))

    super(@$modal)

  open: ->
    @_bindInteractions(@$modal)
    super

  _bindInteractions: (object) ->
    @_bindSaveButton(object)
    @_bindDoNotSaveButton(object)

  _bindSaveButton: (object) ->
    object.find("a.do-save").click (e) =>
      @close()
      @options.doSave()

  _bindDoNotSaveButton: (object) ->
    object.find("a.do-not-save").click (e) =>
      window.location = @options.dashboardURL
