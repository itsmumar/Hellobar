class PayBill
  class Error < StandardError; end
  class MissingCreditCard < Error; end

  def initialize(bill)
    @bill = bill
    @credit_card = bill.subscription.credit_card
  end

  def call
    return bill unless can_be_paid?

    set_final_amount
    pay_bill
    create_bill_for_next_period
    bill
  end

  private

  attr_reader :bill, :credit_card

  def can_be_paid?
    bill.pending? || bill.failed?
  end

  def pay_bill
    return bill.paid! if bill.amount.zero?
    raise MissingCreditCard, 'Could not pay bill without credit card' unless bill.can_pay?

    response = gateway.purchase(bill.amount, credit_card)

    BillingLogger.charge(bill, response.success?)
    if response.success?
      process_successful_response(response)
      track_event(bill)
    else
      process_unsuccessful_response(response)
    end
  end

  def process_successful_response(response)
    create_billing_attempt(response)
    bill.update! authorization_code: response.authorization, status: Bill::PAID
    fix_failed_bills
    regenerate_script
  end

  def process_unsuccessful_response(response)
    create_billing_attempt(response)
    bill.failed!
    Raven.capture_message 'Unsuccessful charge', extra: {
      message: response.message,
      bill: bill.id,
      amount: bill.amount
    }
  end

  def regenerate_script
    bill.site.script.generate
  end

  def set_final_amount
    return if bill.base_amount.nil? || bill.amount.zero?

    bill.discount = calculate_discount
    bill.amount = [bill.base_amount - bill.discount, 0].max
  end

  def calculate_discount
    DiscountCalculator.new(bill.subscription).current_discount
  end

  def create_billing_attempt(response)
    BillingAttempt.create!(
      bill: bill,
      action: BillingAttempt::CHARGE,
      credit_card: credit_card,
      status: response.success? ? BillingAttempt::SUCCESSFUL : BillingAttempt::FAILED,
      response: response.success? ? response.authorization : response.message
    )
  end

  def create_bill_for_next_period
    return if bill.subscription.amount.zero?
    return unless bill.paid?

    CreateBillForNextPeriod.new(bill).call
  end

  def fix_failed_bills
    bill.site.bills_with_payment_issues.each(&:voided!)
  end

  def track_event(bill)
    TrackEvent.new(
      :paid_bill,
      subscription: bill.subscription,
      user: bill.subscription&.user || bill.site.owners.first
    ).call
  end

  def gateway
    @gateway ||= CyberSourceGateway.new
  end
end
