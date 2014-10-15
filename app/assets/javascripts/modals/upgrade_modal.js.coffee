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
    $(template(
      errors: @options,
      siteName: @options.site.display_name
    ))

  open: ->
    @$modal.appendTo($("body"))
    @$modal.find('#yearly-billing').trigger('click')
    @_bindPackageSelection()
    super

  _bindPackageSelection: ->
    @$modal.find('.button').on 'click', (event) =>
      if event.target.dataset.package
        @packageOptions.type = event.target.dataset.package

        options =
          package: @packageOptions
          site: @options.site

        new PaymentModal(options).open()

      @close()

  _bindBillingCycleEvents: ->
    @$modal.find('input[type="radio"]').on 'change', (event) =>
      switch event.target.value
        when 'yearly'
          @packageOptions.cycle = 'yearly'
          @$modal.find('.package-title').addClass('yearly')
        when 'monthly'
          @packageOptions.cycle = 'monthly'
          @$modal.find('.package-title').removeClass('yearly')
