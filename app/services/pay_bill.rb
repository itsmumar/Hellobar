class PayBill
  class Error < StandardError; end
  class MissingPaymentMethod < Error; end

  def initialize(bill)
    raise Error, 'cannot pay a refund' if bill.is_a?(Bill::Refund)
    @bill = bill
    @payment_method = bill.payment_method
  end

  def call
    return bill if cannot_pay?

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

  def cannot_pay?
    !bill.pending? && !bill.problem?
  end

  def charge
    raise MissingPaymentMethod, 'could not pay bill without credit card' unless payment_method

    response = gateway.purchase(bill.amount, payment_method.current_details)
    create_billing_attempt(response)

    BillingLogger.charge(bill, response.success?)

    if response.success?
      bill.update authorization_code: response.authorization
      bill.paid!
      create_bill_for_next_period
      fix_problem_bills
    else
      bill.problem!
      Raven.capture_message 'Unsuccessful charge', extra: {
        message: response.message,
        bill: bill.id,
        amount: bill.amount
      }
    end

    bill
  end

  def set_final_amount
    return if bill.base_amount.nil? || bill.amount.zero?

    bill.discount = bill.is_a?(Bill::Refund) ? 0 : calculate_discount
    bill.amount = [bill.base_amount - bill.discount, 0].max
    CouponUses::ApplyFromReferrals.run(bill: bill)
  end

  def calculate_discount
    DiscountCalculator.new(bill.subscription).current_discount
  end

  def create_billing_attempt(response)
    BillingAttempt.create!(
      bill: bill,
      payment_method_details: payment_method.current_details,
      status: response.success? ? :success : :failed,
      response: response.success? ? response.authorization : response.message
    )
  end

  def create_bill_for_next_period
    Bill::Recurring.create!(
      subscription: bill.subscription,
      amount: bill.subscription.amount,
      description: "#{ bill.subscription.monthly? ? 'Monthly' : 'Yearly' } Renewal",
      grace_period_allowed: true,
      bill_at: 3.days.until(bill.end_date),
      start_date: bill.end_date,
      end_date: bill.end_date + bill.subscription.period
    )
  end

  def fix_problem_bills
    bill.site.bills_with_payment_issues.each(&:voided!)
  end

  def gateway
    @gateway ||= CyberSourceGateway.new
  end
end
