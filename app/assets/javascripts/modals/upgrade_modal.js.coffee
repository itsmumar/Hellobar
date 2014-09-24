class @UpgradeAccountModal extends Modal

  modalName: "upgrade-account"

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#upgrade-account-modal-template").html())
    @$modal = $(@template({errors: @options.errors}))
    @$modal.appendTo($("body"))

    @_bindBillingCycleEvents()

    super(@$modal)

  open: ->
    @$modal.find('#annual-billing').trigger('click')
    super()

  _bindBillingCycleEvents: () ->
    @$modal.find('#annual-billing').on 'change', (event) =>
      @_billedAnnually() if event.target.checked

    @$modal.find('#monthly-billing').on 'change', (event) =>
      @_billedMonthly() if event.target.checked
      
  _billedAnnually: () ->
    @$modal.find('.package-title').addClass('annually')

  _billedMonthly: () ->
    @$modal.find('.package-title').removeClass('annually')
