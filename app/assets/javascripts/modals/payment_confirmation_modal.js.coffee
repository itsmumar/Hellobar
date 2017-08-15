class @PaymentConfirmationModal extends Modal

  modalName: "payment-confirmation"

  constructor: (@options = {}) ->
    @template = Handlebars.compile($("#payment-confirmation-modal-template").html())
    @$modal = $(@template(@_templateOptions()))
    @$modal.appendTo($("body"))

    @_bindCloseButton()

    super(@$modal)

  close: ->
    if @options.successCallback
      @options.successCallback.call(@options.data)
    else
      window.location.reload(true)

    super

  _bindCloseButton: ->
    @$modal.find("a.button").click =>
      @close()

  _templateOptions: ->
    subscription = @options.data.site.current_subscription
    old_subscription = @options.data.old_subscription
    bill = @options.data

    chargeDescription = "Your card ending in #{subscription.credit_card_last_digits} "

    if bill && bill.amount > 0 && bill.status == "paid"
      chargeDescription += "has been charged $#{parseInt(bill.amount).toFixed(2)}."
    else
      chargeDescription += "has not been charged at this time."

    if subscription.schedule == "yearly" && subscription.yearly_amount > 0
      billingSchedule = "You will be billed $#{parseInt(subscription.yearly_amount).toFixed(2)} every year."
    else if subscription.schedule == "monthly" && subscription.monthly_amount > 0
      billingSchedule = "You will be billed $#{parseInt(subscription.monthly_amount).toFixed(2)} every month."
    else
      billingSchedule = ""

    if bill.amount > 0 && bill.status == "paid"
      billingSchedule += " Your next bill will be on #{moment(bill.end_date).format("MMM Do, YYYY")}." if bill.end_date
    else
      billingSchedule += " Your next bill will be on #{moment(bill.bill_at).format("MMM Do, YYYY")}." if bill.status == "pending"

    {
      planName: subscription.type
      billingSchedule: billingSchedule
      chargeDescription: chargeDescription
      isPaidPlan: !@options.isFree
      siteName: @options.siteName
      isUpgrade: @options.data.is_upgrade
      oldPlanName: if old_subscription then old_subscription.type else ""
      showProFeatures: subscription.type == "pro" || subscription.type == "enterprise"
      showEnterpriseFeatures: subscription.type == "enterprise"
    }
