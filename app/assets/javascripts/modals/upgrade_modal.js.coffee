class @UpgradeAccountModal extends Modal

  modalName: "upgrade-account"
  modalTemplate: -> $('script#upgrade-account-modal-template').html()

  packageOptions: 
    type: null
    cycle: null

  constructor: (@options = {}) ->
    @$modal = @buildModal()
    @_bindBillingCycleEvents()

  buildModal: ->
    template = Handlebars.compile(@modalTemplate())
    $(template({errors: @options}))

  open: ->
    @$modal.appendTo($("body"))
    @$modal.find('#annually-billing').trigger('click')
    @_bindPackageSelection()
    super

  #-----------  Select Package  -----------#

  _bindPackageSelection: ->
    @$modal.find('.button').on 'click', (event) =>
      if event.target.dataset.package 
        @packageOptions.type = event.target.dataset.package 
        new PaymentModal(@packageOptions).open()

      @close()

  #-----------  Change Billing Cycle  -----------#

  _bindBillingCycleEvents: ->
    @$modal.find('input[type="radio"]').on 'change', (event) =>
      switch event.target.value
        when 'annually'
          @packageOptions.cycle = 'annually'
          @$modal.find('.package-title').addClass('annually')
        when 'monthly'
          @packageOptions.cycle = 'monthly'
          @$modal.find('.package-title').removeClass('annually')
