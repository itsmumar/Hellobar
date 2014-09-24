class @UpgradeAccountModal extends Modal

  modalName: "upgrade-account"

  packageOptions: 
    type: null
    cycle: null

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#upgrade-account-modal-template").html())
    @$modal = $(@template({errors: @options.errors}))
    @$modal.appendTo($("body"))

    @_bindBillingCycleEvents()

    super(@$modal)

  open: ->
    @$modal.find('#annually-billing').trigger('click')

    @_bindPackageSelection()

    super()
    
  #-----------  Select Package  -----------#

  _bindPackageSelection: () ->
    @$modal.find('.button').on 'click', (event) =>
      if event.target.dataset.package 
        @packageOptions.type = event.target.dataset.package 
        @paymentModal = new PaymentModal(@packageOptions).open()

      @close()

  #-----------  Change Billing Cycle  -----------#

  _bindBillingCycleEvents: () ->
    @$modal.find('input[type="radio"]').on 'change', (event) =>
      switch event.target.value
        when 'annually'
          @packageOptions.cycle = 'annually'
          @$modal.find('.package-title').addClass('annually')
        when 'monthly'
          @packageOptions.cycle = 'monthly'
          @$modal.find('.package-title').removeClass('annually')
