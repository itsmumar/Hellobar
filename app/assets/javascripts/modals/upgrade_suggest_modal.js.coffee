class @UpgradeSuggestModal extends Modal

  modalName: 'upgrade-suggest'

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#upgrade-suggest-modal-template").html())
    @$modal = $(@template())
    @$modal.appendTo($("body"))

    super(@$modal)

  open: ->
    @_bindUpgradePackageSelection(@options)
    super
