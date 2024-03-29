require 'discount_calculator'

class Subscription < ApplicationRecord
  GRANDFATHER_VIEW_LIMIT_EFFECTIVE_DATE = Time.zone.parse('2018-08-16T00:00 UTC').freeze
  GROWTH_START_DATE = Time.zone.parse('2018-04-01T00:00 UTC').freeze
  MONTHLY = 'monthly'.freeze
  YEARLY = 'yearly'.freeze
  SCHEDULES = [MONTHLY, YEARLY].freeze
  DME_TRIAL_PERIOD = 90.days

  ALL = [Free, FreePlus, Growth, Pro, ProComped, ProManaged, ProSpecial, EliteSpecial, Elite, Custom0, Custom1, Custom2, Custom3].freeze

  acts_as_paranoid

  belongs_to :credit_card
  belongs_to :site
  has_many :bills, -> { order 'id' }, inverse_of: :subscription
  has_many :active_bills, -> { merge(Bill.active) }, class_name: 'Bill', inverse_of: :subscription
  has_one :last_paid_bill, -> { paid.order end_date: :desc }, class_name: 'Bill', inverse_of: :subscription

  after_initialize :set_initial_values

  scope :non_free, -> { where('subscriptions.amount > 0') }
  scope :pro, -> { where(type: Subscription::Pro) }
  scope :growth, -> { where(type: Subscription::Growth) }
  scope :elite, -> { where(type: Subscription::Elite) }
  scope :custom, -> { where(type: [Subscription::Custom0, Subscription::Custom1, Subscription::Custom2, Subscription::Custom3]) }
  scope :pro_special, -> { where(type: Subscription::ProSpecial) }
  scope :paid, -> { joins(:bills).merge(Bill.paid.active).distinct }
  scope :exclude_ended_trials, -> { where('trial_end_date is null or trial_end_date > ?', Time.current) }
  scope :ended_trial, -> { where('trial_end_date is not null AND trial_end_date < ?', Time.current) }
  scope :trial, -> { where('trial_end_date is not null AND trial_end_date > ?', Time.current) }

  validates :schedule, presence: true, inclusion: { in: SCHEDULES }
  validates :site, presence: true, associated: true

  class << self
    def from_plan(plan)
      plan, schedule = plan.split('-', 2)
      plan = 'free' if plan == 'starter'
      klass = const_get plan.camelize
      klass.new(schedule: schedule)
    end

    def pro_or_growth_for(user)
      if user.created_at >= GROWTH_START_DATE
        Subscription::Growth
      else
        Pro
      end
    end

    def defaults
      {}
    end

    def estimated_price(user, schedule)
      dummy_sub = new(schedule: schedule)
      discount = DiscountCalculator.new(dummy_sub, user).current_discount
      dummy_sub.amount - discount
    end
  end

  def stripe?
    stripe_subscription_id.present?
  end

  def name
    self.class.defaults[:name]
  end

  def currently_on_trial?
    amount != 0 && active_bills.paid.free.any?
  end

  def trial_days_remaining
    (trial_end_date.to_date - Time.current.to_date).to_i
  end

  def trial_ended?
    currently_on_trial? && Time.current > trial_end_date
  end

  # dedicated marketing expert
  def dme?
    false
  end

  def monthly?
    schedule == MONTHLY
  end

  def yearly?
    schedule == YEARLY
  end

  def period
    monthly? ? 1.month : 1.year
  end

  def trial_period
    return unless trial_end_date
    difference = trial_end_date - created_at
    (difference / 1.day).round.days # round the difference to the day
  end

  def values
    self.class.defaults.merge(schedule: schedule)
  end

  def active_until
    site.active_paid_bill&.end_date
  end

  def days_left
    (active_until.to_date - Date.current).to_i
  end

  def capabilities
    if expired?
      Free::Capabilities.new(self, site)
    else
      self.class::Capabilities.new(self, site)
    end
  end

  def problem_with_payment?
    bills.failed.any?
  end

  def free?
    false
  end

  def expired?
    return false if amount&.zero? # a free subscription never expires
    return false if stripe?
    !last_paid_bill || last_paid_bill.end_date < Date.current
  end

  def <=> other
    Comparison.new(self, other).direction
  end

  def paid?
    values.fetch(:monthly_amount, 0) > 0
  end

  private

  def set_initial_values
    return if persisted?

    values = self.class.defaults
    self.amount ||= monthly? ? values[:monthly_amount] : values[:yearly_amount]
    self.visit_overage ||= values[:visit_overage]
    self.visit_overage_unit ||= values[:visit_overage_unit]
    self.visit_overage_amount ||= values[:visit_overage_amount]
  end
end
