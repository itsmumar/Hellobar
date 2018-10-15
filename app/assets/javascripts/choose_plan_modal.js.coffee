class @ChoosePlanModal extends UpgradeAccountModal
  _bindPackageSelection: ->
    @$modal.find('.button').on 'click', (event) =>
      unless !!$(event.target).attr("disabled")
        packageData = JSON.parse(event.target.dataset.package)
        if packageData.type == "free"
          location.href = '/subscribe/free'
        else
          packageData.schedule = @options.view || @chosenSchedule
          location.href = '/subscribe/' + packageData.name + '-' + packageData.schedule

  _disableCurrentPlanButton: ->
    return if $.isEmptyObject(@options.site.current_subscription)

    @$modal.find("div.button").each (index, button) =>
      buttonPackage = $(button).data("package")
      console.log(buttonPackage.type)
      if buttonPackage.type == @options.current_plan
        if @options.site.current_subscription.trial || !@options.site.current_subscription.payment_valid
          $(button).text("Enter Billing Info")
        else
          $(button).attr("disabled", "disabled")
          prefix = $(button).closest(".package-status").data('btn-prefix') || ""
          $(button).text(prefix + "Current Plan")

