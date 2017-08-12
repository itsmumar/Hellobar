class PayBill
  class Error < StandardError; end
  class MissingCreditCard < Error; end

  def initialize(bill)
    raise Error, 'cannot pay a refund' if bill.is_a?(Bill::Refund)
    @bill = bill
    @credit_card = bill.credit_card
  end

  def call
    return bill if cannot_pay?

    set_final_amount

    if bill.amount.zero?
      create_bill_for_next_period
      bill.paid!
    else
      pay_bill
    end

    bill
  end

  private

  attr_reader :bill, :credit_card

  def cannot_pay?
    !bill.pending? && !bill.problem?
  end

  def pay_bill
    raise MissingCreditCard, 'could not pay bill without credit card' unless credit_card

    response = gateway.purchase(bill.amount, credit_card)

    BillingLogger.charge(bill, response.success?)
    if response.success?
      process_successful_response(response)
    else
      process_unsuccessful_response(response)
    end
  end

  def process_successful_response(response)
    create_billing_attempt(response)
    bill.update authorization_code: response.authorization
    bill.paid!
    create_bill_for_next_period
    fix_problem_bills
  end

  def process_unsuccessful_response(response)
    create_billing_attempt(response)
    bill.problem!
    Raven.capture_message 'Unsuccessful charge', extra: {
      message: response.message,
      bill: bill.id,
      amount: bill.amount
    }
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
      credit_card: credit_card,
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
