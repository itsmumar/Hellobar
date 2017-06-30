require 'discount_calculator'

class Subscription < ActiveRecord::Base
  ALL = [Free, FreePlus, Pro, ProComped, ProManaged, Enterprise].freeze

  belongs_to :payment_method
  belongs_to :site, touch: true
  belongs_to :user
  has_many :bills, -> { order 'id' }, inverse_of: :subscription
  has_many :active_bills, -> { merge(Bill.active) }, class_name: 'Bill', inverse_of: :subscription
  has_one :last_paid_bill, -> { paid.order end_date: :desc }, class_name: 'Bill'

  after_initialize :set_initial_values
  after_create :mark_user_onboarding_as_bought_subscription!

  enum schedule: %i[monthly yearly]

  scope :paid, -> { joins(:bills).merge(Bill.paid.active) }
  scope :active, -> { paid.merge(Bill.without_refunds) }

  validates :schedule, presence: true
  validates :site, presence: true, associated: true

  class << self
    def defaults
      {}
    end

    def estimated_price(user, schedule)
      dummy_sub = new(schedule: schedule)
      discount = DiscountCalculator.new(dummy_sub, user).current_discount
      dummy_sub.amount - discount
    end
  end

  # we use significance to sort subscriptions
  def significance
    0
  end

  def currently_on_trial?
    amount != 0 && payment_method.nil? && active_bills.paid.free.any?
  end

  def period
    monthly? ? 1.month : 1.year
  end

  def values
    self.class.defaults.merge(schedule: schedule)
  end

  def active_until
    site.active_paid_bill.end_date
  end

  def capabilities
    if problem_with_payment? || over?
      Free::Capabilities.new(self, site)
    else
      self.class::Capabilities.new(self, site)
    end
  end

  def problem_with_payment?
    bills.problem.any?
  end

  def over?
    last_paid_bill && last_paid_bill.end_date < Time.current
  end

  def mark_user_onboarding_as_bought_subscription!
    return unless capabilities.acts_as_paid_subscription? && (user || site)
    (user || site.owners.unscoped.first).onboarding_status_setter.bought_subscription!
  end

  def <=> other
    if other.is_a? Subscription
      Comparison.new(self, other).direction
    else
      super
    end
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
