class @PaymentModal extends Modal

  modalName: "payment-account"
  modalTemplate: -> $('script#payment-modal-template').html()

  constructor: (@options = {}) ->
    @$modal = @buildModal()
    @_bindInteractions()

  buildModal: ->
    template = Handlebars.compile(@modalTemplate())
    $(template({errors: @options.errors, package: @options, isAnnual: @isAnnual()}))

  isAnnual: ->
    @options.cycle == 'annually'

  open: ->
    $('body').append(@$modal)
    super

  _bindInteractions: ->
    @$modal.find('.different-plan').on 'click', (event) =>
      new UpgradeAccountModal().open()
      @close()
