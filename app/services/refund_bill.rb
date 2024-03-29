class RefundBill
  class InvalidRefund < StandardError; end
  class MissingCreditCard < StandardError; end

  # @param [Bill] bill
  def initialize(bill)
    @bill = bill
    @amount = bill.amount.abs * -1 # Refunds are always negative
  end

  def call
    raise InvalidRefund, 'Cannot refund an unpaid bill' unless bill.paid?
    check_refund_amount!
    refund
    TrackAffiliateRefund.new(bill).call
  end

  private

  attr_reader :bill, :amount

  delegate :subscription, to: :bill

  # Check that we're not refunding more than they paid
  def check_refund_amount!
    raise InvalidRefund, 'Refund amount cannot be 0' if amount.zero?
  end

  def refund
    if subscription.stripe?
      begin
        response = make_stripe_refund_request
        successful_refund(response.id)
      rescue ArgumentError
        failed_refund
      end
    else
      response = make_refund_request
      if response.success?
        successful_refund(response.authorization)
      else
        failed_refund
      end
    end
  end

  def successful_refund(response)
    Bill.transaction do
      transition_bill_status
      create_success_billing_attempt(bill, response)
      cancel_subscription
    end
  end

  def failed_refund
    create_failed_billing_attempt(bill)
    raise InvalidRefund, 'Invalid response from payment gateway'
  end

  def transition_bill_status
    bill.refund!
  end

  def cancel_subscription
    return unless bill.subscription
    return if bill.one_time?
    bill.subscription.bills.pending.each(&:void!)

    return unless bill.site&.current_subscription

    ChangeSubscription.new(bill.site, subscription: 'free').call
  end

  def create_success_billing_attempt(bill, authorization_code)
    create_billing_attempt(bill, BillingAttempt::SUCCESSFUL, authorization_code)
  end

  def create_failed_billing_attempt(bill)
    create_billing_attempt(bill, BillingAttempt::STATE_FAILED)
  end

  def create_billing_attempt(bill, status, authorization_code = nil)
    bill.billing_attempts.create!(
      response: authorization_code,
      status: status,
      action: BillingAttempt::REFUND
    )
  end

  def make_stripe_refund_request
    customer = Stripe::Customer.retrieve subscription.site.stripe_customer_id
    Stripe::Refund.create(
      charge: customer.charges.data.last.id,
      amount: stripe_amount_in_cents
    )
  end

  def make_refund_request
    gateway.refund(-amount, bill.authorization_code).tap do |response|
      BillingLogger.refund(bill, response.success?)

      unless response.success?
        Raven.capture_message 'Unsuccessful refund', extra: {
          message: response.message,
          bill: bill.id,
          amount: amount
        }
      end
    end
  end

  def stripe_amount_in_cents
    ((amount * - 1) * 100).to_i
  end

  def gateway
    @gateway ||= CyberSourceGateway.new
  end
end
