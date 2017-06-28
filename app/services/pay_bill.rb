class PayBill
  class Error < StandardError; end
  class MissingPaymentMethod < Error; end

  def initialize(bill)
    @bill = bill
    @payment_method = bill.payment_method
  end

  def call
    return bill unless bill.pending?

    set_final_amount

    if bill.amount.zero?
      create_bill_for_next_period
      bill.tap(&:paid!)
    else
      charge
    end
  end

  private

  attr_reader :bill, :payment_method

  def charge
    raise MissingPaymentMethod, 'could not pay bill without credit card' unless payment_method

    success, response = payment_method.charge(bill.amount)
    create_billing_attempt(success, response)

    BillingLogger.charge(bill, success)

    if success
      bill.update authorization_code: response
      bill.paid!
      create_bill_for_next_period
    else
      Raven.capture_message 'Unsuccessful charge', extra: {
        message: response,
        bill: bill.id,
        amount: bill.amount
      }
    end

    bill
  end

  def set_final_amount
    return if bill.base_amount.nil?

    bill.discount = bill.is_a?(Bill::Refund) ? 0 : calculate_discount
    bill.amount = [bill.base_amount - bill.discount, 0].max
    CouponUses::ApplyFromReferrals.run(bill: bill)
  end

  def calculate_discount
    DiscountCalculator.new(bill.subscription).current_discount
  end

  def create_billing_attempt(success, response)
    BillingAttempt.create!(
      bill: bill,
      payment_method_details: payment_method.current_details,
      status: success ? :success : :failed,
      response: response
    )
  end

  def create_bill_for_next_period
    Bill::Recurring.create!(
      subscription: bill.subscription,
      amount: bill.subscription.amount,
      description: "#{ bill.subscription.monthly? ? 'Monthly' : 'Yearly' } Renewal",
      grace_period_allowed: true,
      bill_at: bill.end_date,
      start_date: bill.end_date,
      end_date: bill.end_date + bill.subscription.period
    )
  end
end
