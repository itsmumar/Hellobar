class Bill < ApplicationRecord
  include AASM

  aasm column: :status do
    state :pending, initial: true
    state :paid
    state :voided
    state :failed
    state :refunded
    state :chargedback

    event :pay do
      before do |authorization_code|
        self.authorization_code = authorization_code
      end

      transitions from: %i[pending failed], to: :paid
    end

    event :fail do
      transitions from: %i[pending failed], to: :failed
    end

    event :void do
      transitions to: :voided # allow to void bill from any state
    end

    event :refund do
      transitions from: :paid, to: :refunded
    end

    event :chargeback do
      transitions from: :paid, to: :chargedback
    end

    after_all_transitions :track_status_set_at
  end

  class InvalidBillingAmount < StandardError
    attr_reader :amount

    def initialize(amount)
      @amount = amount
      super "Amount was: #{ amount&.to_f.inspect }"
    end
  end

  belongs_to :subscription, inverse_of: :bills
  has_many :billing_attempts, -> { order 'id' }, dependent: :destroy, inverse_of: :bill
  has_many :coupon_uses, dependent: :destroy
  has_one :site, through: :subscription, inverse_of: :bills
  has_one :affiliate_commission, inverse_of: :bill

  delegate :site_id, to: :subscription

  before_save :check_amount
  before_validation :set_base_amount, :check_amount

  scope :non_free, -> { where('bills.amount > 0') }
  scope :free, -> { where(amount: 0) }
  scope :due_now, -> { pending.non_free.where('? >= bill_at', Time.current) }
  scope :not_voided, -> { where.not(status: STATE_VOIDED) }
  scope :not_pending, -> { where.not(status: STATE_PENDING) }
  scope :active, -> { not_voided.where('DATE(bills.start_date) <= :now AND DATE(bills.end_date) >= :now', now: Date.current) }

  validates :subscription_id, presence: true
  validates :status, presence: true

  def during_trial_subscription?
    subscription.amount != 0 && subscription.credit_card.nil? && amount == 0 && paid?
  end

  def check_amount
    raise InvalidBillingAmount, amount if !amount || amount < 0
  end

  def problem_reason
    billing_attempts.last&.response
  end

  def credit_card_attached?
    return unless (credit_card = subscription.credit_card)

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

  def last_billing_attempt
    billing_attempts.order(:id).last
  end

  def used_credit_card
    credit_card_id = (successful_billing_attempt || last_billing_attempt)&.credit_card_id
    credit_card_id && CreditCard.unscoped.find(credit_card_id)
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

  def track_status_set_at
    self.status_set_at = Time.current
  end
end
