class RefundBill
  class InvalidRefund < StandardError; end
  class MissingCreditCard < StandardError; end

  # @param [Bill::Recurring] bill
  def initialize(bill)
    @bill = bill
    @amount = bill.amount.abs * -1 # Refunds are always negative
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
    raise InvalidRefund, 'Refund amount cannot be 0' if amount.zero?
  end

  def refund
    response = make_refund_request

    if response.success?
      Bill.transaction do
        create_success_refund_bill(response.authorization).tap do |bill|
          create_billing_attempt(bill)
          cancel_subscription
        end
      end
    else
      Bill.transaction do
        create_failed_refund_bill.tap do |bill|
          create_billing_attempt(bill)
        end
      end
    end
  end

  def cancel_subscription
    return unless bill.subscription
    bill.subscription.bills.pending.each(&:voided!)

    return unless bill.site&.current_subscription

    ChangeSubscription.new(bill.site, subscription: 'free').call
  end

  def successful_billing_attempt
    @successful_billing_attempt ||= bill.successful_billing_attempt
  end

  def create_success_refund_bill authorization_code
    create_refund_bill! status: Bill::REFUNDED, authorization_code: authorization_code
  end

  def create_failed_refund_bill
    create_refund_bill! status: Bill::VOIDED
  end

  def create_refund_bill!(status:, authorization_code: nil)
    Bill::Refund.create!(
      subscription_id: bill.subscription_id,
      amount: amount,
      description: 'Refund due to customer service request',
      bill_at: Time.current,
      start_date: Time.current,
      end_date: bill.end_date,
      refunded_bill: bill,
      status: status,
      authorization_code: authorization_code
    )
  end

  def create_billing_attempt(bill)
    bill.billing_attempts.create!(
      response: bill.authorization_code,
      status: bill.refunded? ? BillingAttempt::SUCCESSFUL : BillingAttempt::FAILED,
      action: BillingAttempt::REFUND
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

  def gateway
    @gateway ||= CyberSourceGateway.new
  end
end
