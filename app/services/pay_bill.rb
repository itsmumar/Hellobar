class PayBill
  class Error < StandardError; end
  class MissingCreditCard < Error; end

  DEFAULT_CURRENCY = 'usd'.freeze

  def initialize(bill, stripe = false)
    @bill = bill
    @credit_card = bill.subscription.credit_card
    @stripe = stripe
  end

  def call
    return bill unless can_be_paid?

    set_final_amount
    if bill.subscription.stripe? && stripe
      pay_stripe_bill
    elsif !bill.subscription.stripe?
      pay_bill
    end

    create_bill_for_next_period
    bill
  end

  private

  attr_reader :bill, :credit_card, :stripe

  def can_be_paid?
    bill.pending? || bill.failed?
  end

  def pay_stripe_bill
    return bill.pay! if bill.amount.zero?
    raise MissingCreditCard, 'Could not pay bill without credit card' unless bill.credit_card_attached?

    begin
      customer = Stripe::Customer.retrieve(bill.subscription.site.stripe_customer_id) # TODO: Pass current_user to this.
      response = Stripe::Charge.create(
        customer: customer.id,
        amount: (bill.amount * 100),
        description: 'Monthly View Limit Overage Fee',
        currency: DEFAULT_CURRENCY
      )

      BillingAttempt.create!(
        bill: bill,
        action: BillingAttempt::CHARGE,
        credit_card: credit_card,
        status: BillingAttempt::SUCCESSFUL,
        response: response.id
      )
    rescue StandardError
      BillingAttempt.create!(
        bill: bill,
        action: BillingAttempt::CHARGE,
        credit_card: credit_card,
        status:  BillingAttempt::STATE_FAILED,
        response: 'Stripe Error: Could not pay overage bill'
      )
    end
  end

  def pay_bill
    return bill.pay! if bill.amount.zero?
    raise MissingCreditCard, 'Could not pay bill without credit card' unless bill.credit_card_attached?

    response = gateway.purchase(bill.amount, credit_card)

    BillingLogger.charge(bill, response.success?)

    if response.success?
      process_successful_response(response)
      track_event(bill)
      store_affiliate_commission(bill)
    else
      process_unsuccessful_response(response)
    end
  end

  def process_successful_response(response)
    create_billing_attempt(response)
    bill.pay!(response.authorization)
    fix_failed_bills
    regenerate_script
  end

  def process_unsuccessful_response(response)
    create_billing_attempt(response)
    bill.fail!
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
      status: response.success? ? BillingAttempt::SUCCESSFUL : BillingAttempt::STATE_FAILED,
      response: response.success? ? response.authorization : response.message
    )
  end

  def create_bill_for_next_period
    return if bill.subscription.amount.zero? || bill.one_time?
    return unless bill.paid?

    CreateBillForNextPeriod.new(bill).call
  end

  def fix_failed_bills
    bill.site.bills_with_payment_issues.each(&:void!)
  end

  def track_event(bill)
    TrackEvent.new(
      :paid_bill,
      subscription: bill.subscription,
      user: bill.subscription&.credit_card&.user || bill.site.owners.first
    ).call
  end

  def store_affiliate_commission bill
    return unless Rails.env.production?

    TrackAffiliateCommissionJob.perform_later bill
  end

  def gateway
    @gateway ||= CyberSourceGateway.new
  end
end
