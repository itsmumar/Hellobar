class @ExitIntentModal extends Modal

  modalName: 'exit-intent'

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#exit-intent-modal-template").html())
    @$modal = $(@template())
    @$modal.appendTo($("body"))

    super(@$modal)

  open: ->
    @_bindUpgradePackageSelection(@options);
    super

