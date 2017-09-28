class RefundBill
  class InvalidRefund < StandardError; end
  class MissingCreditCard < StandardError; end

  # @param [Bill::Recurring] bill
  # @param [Float] amount, default bill.amount
  def initialize(bill, amount: bill.amount)
    @bill = bill
    @amount = amount.abs * -1 # Refunds are always negative
  end

  def call
    raise InvalidRefund, 'Cannot refund an unpaid bill' unless bill.paid?
    check_refund_amount!
    refund
  end

  private

  attr_reader :bill, :amount

  delegate :subscription, to: :bill

  # Check that we're not refunding more than they paid
  def check_refund_amount!
    raise InvalidRefund, 'Cannot refund more than paid amount' if fully_paid?
    raise InvalidRefund, 'Refund amount cannot be 0' if amount.zero?
  end

  def refund
    response = make_refund_request

    if response.success?
      create_success_refund_bill(response) { cancel_subscription }
    else
      create_failed_refund_bill(response)
    end
  end

  def cancel_subscription
    bill.subscription.bills.pending.each(&:voided!)
    ChangeSubscription.new(bill.site, subscription: 'free').call
  end

  def fully_paid?
    (bill.amount + amount + previous_refunds) < 0
  end

  def previous_refunds
    successful_billing_attempt.refunds.sum(:amount)
  end

  def successful_billing_attempt
    @successful_billing_attempt ||= bill.successful_billing_attempt
  end

  def create_success_refund_bill(response)
    attributes = { status: :paid, authorization_code: response.authorization }

    create_refund_bill!(attributes).tap do |refund_bill|
      create_billing_attempt(refund_bill, response)
      yield refund_bill
    end
  end

  def create_failed_refund_bill(response)
    create_refund_bill!(status: :voided).tap do |refund_bill|
      create_billing_attempt(refund_bill, response)
    end
  end

  def create_refund_bill!(status:, authorization_code: nil)
    Bill::Refund.create!(
      subscription: bill.subscription,
      amount: amount,
      description: 'Refund due to customer service request',
      bill_at: Time.current,
      start_date: Time.current,
      end_date: bill.end_date,
      refunded_billing_attempt: successful_billing_attempt,
      refunded_bill: bill,
      status: status,
      authorization_code: authorization_code
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

  def credit_card
    @credit_card ||= bill.paid_with_credit_card
  end

  def create_billing_attempt(refund_bill, response)
    BillingAttempt.create!(
      bill: refund_bill,
      credit_card: credit_card,
      status: response.success? ? :success : :failed,
      response: response.success? ? response.authorization : response.message
    )
  end

  def gateway
    @gateway ||= CyberSourceGateway.new
  end
end
