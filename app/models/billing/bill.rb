class Bill < ActiveRecord::Base
  class StatusAlreadySet < StandardError
    def initialize(bill, status)
      super "Can not change status once set. Was #{ bill.status.inspect } trying to set to #{ status.inspect }"
    end
  end

  class InvalidStatus < StandardError; end
  class InvalidBillingAmount < StandardError
    attr_reader :amount

    def initialize(amount)
      @amount = amount
      super "Amount was: #{ amount&.to_f.inspect }"
    end
  end

  # rubocop: disable Rails/HasManyOrHasOneDependent
  belongs_to :subscription, inverse_of: :bills
  belongs_to :refund, inverse_of: :refunded_bill, class_name: 'Bill::Refund'
  has_many :billing_attempts, -> { order 'id' }, dependent: :destroy
  has_many :coupon_uses, dependent: :destroy
  has_one :site, through: :subscription, inverse_of: :bills
  has_one :credit_card, -> { with_deleted }, through: :subscription

  validates :subscription, presence: true
  delegate :site_id, to: :subscription

  before_save :check_amount
  before_validation :set_base_amount, :check_amount

  enum status: %i[pending paid voided problem]

  scope :recurring, -> { where(type: Recurring) }
  scope :with_amount, -> { where('bills.amount > 0') }
  scope :non_free, -> { where.not(amount: 0) }
  scope :free, -> { where(amount: 0) }
  scope :due_now, -> { pending.with_amount.where('? >= bill_at', Time.current) }
  scope :not_void, -> { where.not(status: statuses[:voided]) }
  scope :active, -> { not_void.where('bills.start_date <= :now AND bills.end_date >= :now', now: Time.current) }
  scope :without_refunds, -> { where(refund_id: nil).where.not(type: Bill::Refund) }
  scope :paid_or_problem, -> { where(status: statuses.values_at(:paid, :problem)) }

  def during_trial_subscription?
    subscription.amount != 0 && subscription.credit_card.nil? && amount == 0 && paid?
  end

  def check_amount
    raise InvalidBillingAmount, amount if !amount || amount < 0
  end

  def status=(value)
    value = value.to_sym
    return if status == value
    raise StatusAlreadySet.new(self, status) unless status == :pending || status == :problem || value == :voided

    status_value = Bill.statuses[value.to_sym]
    raise InvalidStatus, "Invalid status: #{ value.inspect }" unless status_value
    self[:status] = status_value
    self.status_set_at = Time.current
  end

  def status
    super.to_sym
  end

  def problem_reason
    billing_attempts.last&.response
  end

  def can_pay?
    return unless credit_card

    !credit_card.deleted? && credit_card.token.present?
  end

  def due_at(credit_card = nil)
    # it is due now
    return bill_at unless grace_period_allowed && credit_card&.grace_period

    bill_at + credit_card.grace_period
  end

  def past_due?(credit_card = nil)
    Time.current >= due_at(credit_card)
  end

  def paid_with_credit_card
    successful_billing_attempt&.credit_card
  end

  def successful_billing_attempt
    billing_attempts.success.first
  end

  def calculate_discount
    DiscountCalculator.new(subscription).current_discount
  end

  def estimated_amount
    (base_amount || amount) - calculate_discount
  end

  private

  def set_base_amount
    self.base_amount ||= amount
  end
end
