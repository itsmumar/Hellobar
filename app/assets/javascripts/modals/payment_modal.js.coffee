class @PaymentModal extends Modal

  modalName: "payment-account"

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#payment-modal-template").html())
    @$modal = $(@template({errors: @options.errors, package: @options}))
    @$modal.appendTo($("body"))

    super(@$modal)
