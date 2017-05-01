require 'billing_log'
require 'discount_calculator'

class Subscription < ActiveRecord::Base
  include BillingAuditTrail
  ALL = [Free, FreePlus, Pro, ProComped, ProManaged, Enterprise].freeze

  belongs_to :payment_method
  belongs_to :site, touch: true
  belongs_to :user
  has_many :bills, -> { order 'id' }, inverse_of: :subscription

  after_initialize :set_initial_values
  after_create :mark_user_onboarding_as_bought_subscription!

  enum schedule: %i[monthly yearly]

  scope :paid, -> { joins(:bills).merge(Bill.active) }
  scope :active, -> { paid.merge(Bill.without_refunds) }

  class << self
    def values_for(_site)
      # Just return the defaults for now, in the future we can
      # offer per-site discounts, etc
      defaults
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

  # we use significance to sort subscriptions
  def significance
    0
  end

  def currently_on_trial?
    amount != 0 && payment_method.nil? && active_bills.any? { |b| b.amount == 0 && b.paid? }
  end

  def values
    self.class.values_for(site).merge(schedule: schedule)
  end

  def pending_bills(reload = false)
    bills(reload).select { |b| b.status == :pending }
  end

  def paid_bills(reload = false)
    bills(reload).select { |b| b.status == :paid }
  end

  def active_bills(reload = false, date = nil)
    date ||= Time.current
    bills(reload).select { |b| b.active_during(date) }
  end

  def active_until
    bills.paid.maximum(:end_date).try(:localtime)
  end

  def capabilities(reload = false)
    if reload || !@capabilities
      # If we are in good standing we just return our normal
      # capabilities, otherwise we return the default capabilities
      active_bills(reload).each do |bill|
        payment_method = nil
        if site && site.current_subscription && site.current_subscription.payment_method
          payment_method = site.current_subscription.payment_method
        end
        if bill.problem_with_payment?(payment_method)
          @capabilities = ProblemWithPayment::Capabilities.new(self, site)
          return @capabilities
        end
      end
      @capabilities = self.class::Capabilities.new(self, site)
    end
    @capabilities
  end

  def problem_with_payment?
    capabilities.instance_of?(Subscription::ProblemWithPayment::Capabilities)
  end

  def set_initial_values
    return if persisted?

    values = self.class.values_for(site)
    self.amount ||= monthly? ? values[:monthly_amount] : values[:yearly_amount]
    self.visit_overage ||= values[:visit_overage]
    self.visit_overage_unit ||= values[:visit_overage_unit]
    self.visit_overage_amount ||= values[:visit_overage_amount]
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
end
