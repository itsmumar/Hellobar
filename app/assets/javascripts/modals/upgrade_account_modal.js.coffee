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

    @source = @options.source || @options.upgradeBenefit

    super

  _bindPackageSelection: ->
    @$modal.find('.button').on 'click', (event) =>
      unless !!$(event.target).attr("disabled")
        packageData = JSON.parse(event.target.dataset.package)
        if packageData.type == "free"
          new DowngradeSiteModal({site: @options.site}).open()
        else
          packageData.schedule = @chosenSchedule

          options =
            source: "package-selected"
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
        if @options.site.current_subscription.trial || !@options.site.current_subscription.payment_valid
          $(button).text("Enter Billing Info")
        else
          $(button).attr("disabled", "disabled")
          prefix = $(button).closest(".package-status").data('btn-prefix') || ""
          $(button).text(prefix + "Current Plan")

  _invalidPermissions: ->
    @$modal.find("div.button").each (index, button) =>
      if !$(button).attr("disabled")
        $(button).attr("disabled", "disabled")
        $(button).addClass("disabled-promo")
        $(button).text("Email the account owner to upgrade this site:")

    @$modal.find(".email-links").each (index, element) =>
      $(element).addClass("disabled-link")
      $(element).show()
