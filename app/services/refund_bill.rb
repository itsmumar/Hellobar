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
    raise InvalidRefund, 'Cannot refund unsuccessful billing attempt' unless successful_billing_attempt
    raise MissingCreditCard, 'Could not find credit card' unless subscription.credit_card
    check_refund_amount!

    refund_bill = create_refund_bill!
    refund_attempt = refund!(refund_bill)
    [refund_bill, refund_attempt]
  end

  private

  attr_reader :bill, :amount

  delegate :subscription, to: :bill

  # cache billing attempt in case it will change
  def successful_billing_attempt
    @successful_billing_attempt ||= bill.successful_billing_attempt
  end

  # Check that we're not refunding more than they paid
  def check_refund_amount!
    raise InvalidRefund, 'Cannot refund more than paid amount' if bill.amount + (amount + previous_refunds) < 0
    raise InvalidRefund, 'Refund amount cannot be 0' if amount.zero?
  end

  def previous_refunds
    successful_billing_attempt.refunds.sum(:amount)
  end

  def create_refund_bill!
    Bill::Refund.create!(
      subscription: bill.subscription,
      amount: amount,
      description: 'Refund due to customer service request',
      bill_at: Time.current,
      start_date: Time.current,
      end_date: bill.end_date,
      refunded_billing_attempt: successful_billing_attempt,
      refunded_bill: bill
    )
  end

  def refund!(refund_bill)
    response = gateway.refund(-amount, bill.authorization_code)

    BillingLogger.refund(bill, response.success?)

    if response.success?
      refund_bill.update authorization_code: response.authorization, status: :paid
    else
      Raven.capture_message 'Unsuccessful refund', extra: {
        message: response.message,
        bill: bill.id,
        amount: amount
      }
    end
    create_billing_attempt(refund_bill, response)
  end

  def credit_card
    successful_billing_attempt.credit_card
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
