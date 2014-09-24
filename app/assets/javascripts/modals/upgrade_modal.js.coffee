class @UpgradeAccountModal extends Modal

  modalName: "upgrade-account"

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#upgrade-account-modal-template").html())
    @$modal = $(@template({errors: @options.errors}))
    @$modal.appendTo($("body"))

    super(@$modal)
