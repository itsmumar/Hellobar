class @UpgradeAccountModal extends Modal

  modalName: "upgrade-account"
  modalTemplate: -> $('script#upgrade-account-modal-template').html()

  chosenSchedule: "yearly"

  constructor: (@options = {}) ->
    @$modal = @buildModal()
    @_bindBillingCycleEvents()

  buildModal: ->
    template = Handlebars.compile(@modalTemplate())
    $(template(
      errors: @options,
      siteName: @options.site.display_name,
      showFreePlus: @options.site.current_subscription.type == "free plus"
      upgradeBenefit: @options.upgradeBenefit
    ))

  open: ->
    @$modal.appendTo($("body"))
    @$modal.find('#yearly-billing').trigger('click')
    @_disableCurrentPlanButton()
    if !@options.site.view_billing then @_invalidPermissions()
    @_bindPackageSelection()
    super

  close: (continuing = false) ->
    if !continuing && @options.site.current_subscription.type == "free"
      Intercom('trackEvent', 'upgrade-viewed');
    super

  _bindPackageSelection: ->
    @$modal.find('.button').on 'click', (event) =>
      unless !!$(event.target).attr("disabled")
        packageData = JSON.parse(event.target.dataset.package)
        packageData.schedule = @chosenSchedule

        options =
          package: packageData
          site: @options.site
          successCallback: @options.successCallback
          upgradeBenefit: @options.upgradeBenefit

        new PaymentModal(options).open()

      @close(true)

  _bindBillingCycleEvents: ->
    @$modal.find('input[type="radio"]').on 'change', (event) =>
      switch event.target.value
        when 'yearly'
          @chosenSchedule = 'yearly'
          @$modal.find('.package-title').addClass('yearly')
        when 'monthly'
          @chosenSchedule = 'monthly'
          @$modal.find('.package-title').removeClass('yearly')

  _disableCurrentPlanButton: ->
    return if $.isEmptyObject(@options.site.current_subscription)

    @$modal.find("div.button").each (index, button) =>
      buttonPackage = $(button).data("package")

      if buttonPackage.type == @options.site.current_subscription.type
        $(button).attr("disabled", "disabled")
        $(button).text("Current Plan")

  _invalidPermissions: ->
    @$modal.find("div.button").each (index, button) =>
      if !$(button).attr("disabled")
        $(button).attr("disabled", "disabled")
        $(button).text("Contact the account owner to upgrade this site.")

    @$modal.find(".email-links").each (index, element) =>
      $(element).show()
