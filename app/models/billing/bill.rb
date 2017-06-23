class Bill < ActiveRecord::Base
  class StatusAlreadySet < StandardError; end
  class InvalidStatus < StandardError; end
  class BillingEarly < StandardError; end
  class InvalidBillingAmount < StandardError
    attr_reader :amount

    def initialize(amount)
      @amount = amount.to_f
      super("Amount was: #{ amount.to_f.inspect }")
    end
  end

  class MissingPaymentMethod < StandardError; end

  serialize :metadata, JSON

  belongs_to :subscription, inverse_of: :bills
  belongs_to :refund, inverse_of: :refunded_bill, class_name: 'Bill::Refund'
  has_many :billing_attempts, -> { order 'id' }
  has_many :coupon_uses
  has_one :site, through: :subscription, inverse_of: :bills
  has_one :payment_method, through: :subscription

  validates :subscription, presence: true
  delegate :site_id, to: :subscription

  before_save :check_amount
  before_validation :set_base_amount, :check_amount

  enum status: %i[pending paid voided]

  scope :recurring, -> { where(type: Recurring) }
  scope :with_amount, -> { where('bills.amount > 0') }
  scope :due_now, -> { pending.with_amount.where('? >= bill_at', Time.current) }
  scope :active, -> { paid.where('bills.start_date <= :now AND bills.end_date >= :now', now: Time.current) }
  scope :without_refunds, -> { where(bills: { refund_id: nil }).where.not(type: Bill::Refund) }

  def create_next_bill!
    Recurring.create!(
      subscription: subscription,
      amount: subscription.amount,
      description: "#{ subscription.monthly? ? 'Monthly' : 'Yearly' } Renewal",
      grace_period_allowed: true,
      bill_at: end_date,
      start_date: end_date,
      end_date: end_date + subscription.period
    )
  end

  def during_trial_subscription?
    subscription.amount != 0 && subscription.payment_method.nil? && amount == 0 && paid?
  end

  def set_base_amount
    self.base_amount ||= amount
  end

  def check_amount
    raise InvalidBillingAmount, amount if !amount || amount < 0
  end

  def status=(value)
    value = value.to_sym
    return if status == value
    raise StatusAlreadySet, "Can not change status once set. Was #{ status.inspect } trying to set to #{ value.inspect }" unless status == :pending || value == :voided

    status_value = Bill.statuses[value.to_sym]
    raise InvalidStatus, "Invalid status: #{ value.inspect }" unless status_value
    self[:status] = status_value
    self.status_set_at = Time.current
  end

  def status
    super.to_sym
  end

  def active_during(date)
    return false if voided?
    return false if start_date && start_date > date
    return false if end_date && end_date < date
    true
  end

  def due_at(payment_method = nil)
    if grace_period_allowed && payment_method&.current_details&.grace_period
      return bill_at + payment_method.current_details.grace_period
    end
    # Otherwise it is due now
    bill_at
  end

  def past_due?(payment_method = nil)
    Time.current >= due_at(payment_method)
  end

  def should_bill?
    pending? && Time.current >= bill_at
  end

  def problem_with_payment?(payment_method = nil)
    return false if paid? || voided? || amount == 0
    # If pending see if we are past due and we have
    # tried billing them at least once
    return true if past_due?(payment_method) && (payment_method.nil? || !billing_attempts.empty?)
    # False otherwise
    false
  end

  def paid_with_payment_method_detail
    successful_billing_attempt.try(:payment_method_details)
  end

  def successful_billing_attempt
    billing_attempts.success.first
  end

  def calculate_discount
    DiscountCalculator.new(subscription).current_discount
  end

  def set_final_amount!
    return if paid? || base_amount.nil?

    self.discount = is_a?(Refund) ? 0 : calculate_discount
    self.amount = [self.base_amount - discount, 0].max
    CouponUses::ApplyFromReferrals.run(bill: self)
  end

  def estimated_amount
    (base_amount || amount) - calculate_discount
  end
end
