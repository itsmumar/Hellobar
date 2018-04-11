require 'discount_calculator'

class Subscription < ApplicationRecord
  GROWTH_START_DATE = Time.zone.parse('2018-04-01T00:00 UTC').freeze
  MONTHLY = 'monthly'.freeze
  YEARLY = 'yearly'.freeze
  SCHEDULES = [MONTHLY, YEARLY].freeze

  ALL = [Free, FreePlus, Growth, Pro, ProComped, ProManaged, Enterprise].freeze

  acts_as_paranoid

  belongs_to :credit_card
  belongs_to :site
  belongs_to :user
  has_many :bills, -> { order 'id' }, inverse_of: :subscription
  has_many :active_bills, -> { merge(Bill.active) }, class_name: 'Bill', inverse_of: :subscription
  has_one :last_paid_bill, -> { paid.order end_date: :desc }, class_name: 'Bill', inverse_of: :subscription

  after_initialize :set_initial_values

  scope :paid, -> { joins(:bills).merge(Bill.paid.active) }
  scope :active, -> { paid.merge(Bill.without_refunds.without_chargebacks) }
  scope :exclude_ended_trials, -> { where('trial_end_date is null or trial_end_date > ?', Time.current) }

  validates :schedule, presence: true, inclusion: { in: SCHEDULES }
  validates :site, presence: true, associated: true

  class << self
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

  def name
    self.class.defaults[:name]
  end

  def currently_on_trial?
    amount != 0 && credit_card.nil? && active_bills.paid.free.any?
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
