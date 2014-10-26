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
    bill = @options.data.bill

    if subscription.schedule == "yearly" && subscription.yearly_amount > 0
      billingSchedule = "; your card ending in #{subscription.payment_method_number} will be billed $#{parseInt(subscription.yearly_amount).toFixed(2)} per year"
    else if subscription.schedule == "monthly" && subscription.monthly_amount > 0
      billingSchedule = "; your card ending in #{subscription.payment_method_number} will be billed $#{parseInt(subscription.monthly_amount).toFixed(2)} per month"
    else
      billingSchedule = ""

    if bill && bill.amount > 0 && bill.status == "paid"
      chargeDescription = "Your card has been charged $#{parseInt(bill.amount).toFixed(2)}."
      chargeDescription += " Your next bill is due on #{moment(bill.end_date).format("MMM Do, YYYY")}." if bill.end_date
    else
      chargeDescription = "Your card has not been charged at this time."
      chargeDescription += " Your next bill is due on #{moment(bill.bill_at).format("MMM Do, YYYY")}." if bill.status == "pending"

    {
      planName: subscription.type
      billingSchedule: billingSchedule
      chargeDescription: chargeDescription
      isPaidPlan: !@options.isFree
    }
