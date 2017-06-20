class PayBill
  def initialize(bill)
    @bill = bill
    @payment_method = bill.payment_method
  end

  def call
    return bill if !bill.pending? || bill.due_at(payment_method) > Time.current

    set_final_amount

    charge unless bill.amount.zero?
    create_bill_for_next_period
    bill.tap(&:paid!)
  end

  private

  attr_reader :bill, :payment_method

  def charge
    raise 'could not pay bill with negative amount' if bill.amount < 0
    success, response = payment_method.charge(bill.amount)
    create_billing_attempt(success, response)
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
      payment_method: payment_method,
      status: success ? :success : :failed,
      response: response
    )
    raise response.inspect unless success
  end

  def create_bill_for_next_period
    bill.create_next_bill!
  end
end
