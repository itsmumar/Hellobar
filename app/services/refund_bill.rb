class RefundBill
  class InvalidRefund < RuntimeError; end

  # @param [Bill::Recurring] bill
  # @param [Float] amount, default bill.amount
  def initialize(bill, amount = bill.amount)
    @bill = bill
    @amount = amount.abs * -1 # Refunds are always negative
  end

  def call
    raise InvalidRefund, 'Cannot refund unsuccessful billing attempt' unless successful_billing_attempt

    # Check that we're not refunding more than they paid
    previous_refunds = bill.subscription.bills.select { |x| x.is_a?(Bill::Refund) && x.refunded_billing_attempt_id == id }.map(&:amount).sum
    raise InvalidRefund, 'Cannot refund more than paid amount' if bill.amount + (amount + previous_refunds) < 0

    now = Time.now
    refund_bill = Bill::Refund.new(
      subscription: bill.subscription,
      amount: amount,
      description: 'Refund due to customer service request',
      bill_at: now,
      start_date: now,
      end_date: bill.end_date,
      refunded_billing_attempt: successful_billing_attempt
    )
    refund_attempt = refund_bill.attempt_billing!
    refund_bill.save!

    [refund_bill, refund_attempt]
  end

  private

  attr_reader :bill, :amount

  delegate :successful_billing_attempt, to: :bill
end
