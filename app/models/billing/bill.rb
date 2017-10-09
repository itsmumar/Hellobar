class Bill < ActiveRecord::Base
  PENDING = 'pending'.freeze
  PAID = 'paid'.freeze
  VOIDED = 'voided'.freeze
  FAILED = 'failed'.freeze
  STATUSES = [PENDING, PAID, VOIDED, FAILED].freeze

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

  delegate :site_id, to: :subscription

  before_save :check_amount
  before_validation :set_base_amount, :check_amount

  STATUSES.each do |status|
    scope status, -> { where(status: status) }
  end

  scope :recurring, -> { where(type: Recurring) }
  scope :with_amount, -> { where('bills.amount > 0') }
  scope :non_free, -> { where.not(amount: 0) }
  scope :free, -> { where(amount: 0) }
  scope :due_now, -> { pending.with_amount.where('? >= bill_at', Time.current) }
  scope :not_voided, -> { where.not(status: VOIDED) }
  scope :active, -> { not_voided.where('bills.start_date <= :now AND bills.end_date >= :now', now: Time.current) }
  scope :without_refunds, -> { where(refund_id: nil).where.not(type: Bill::Refund) }
  scope :paid_or_failed, -> { where(status: [PAID, FAILED]) }

  validates :subscription, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  # defines #pending? #paid? #voided? #failed?
  delegate(*STATUSES.map { |status| status + '?' }, to: :status)

  def during_trial_subscription?
    subscription.amount != 0 && subscription.credit_card.nil? && amount == 0 && paid?
  end

  def check_amount
    raise InvalidBillingAmount, amount if !amount || amount < 0
  end

  def status=(value)
    value = value.to_s
    return if status == value
    raise StatusAlreadySet.new(self, status) unless can_status_be_changed?(value)

    self[:status] = value
    self.status_set_at = Time.current
  end

  # this gives you a prettier way to test for equality
  #   i.e: bill.status.paid? || bill.status.voided?
  def status
    ActiveSupport::StringInquirer.new(super).freeze
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
    billing_attempts.successful.first
  end

  def calculate_discount
    DiscountCalculator.new(subscription).current_discount
  end

  def estimated_amount
    (base_amount || amount) - calculate_discount
  end

  def pending!
    update! status: PENDING
  end

  def paid!
    update! status: PAID
  end

  def void!
    update! status: VOIDED
  end

  def fail!
    update! status: FAILED
  end

  private

  def can_status_be_changed?(value)
    value == VOIDED || [PENDING, FAILED].include?(status)
  end

  def set_base_amount
    self.base_amount ||= amount
  end
end
