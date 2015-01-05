require 'billing_log'

class Subscription < ActiveRecord::Base
  include BillingAuditTrail
  belongs_to :user
  belongs_to :site
  belongs_to :payment_method
  enum schedule: [:monthly, :yearly]
  has_many :bills, -> {order "id"}, inverse_of: :subscription

  class << self
    def values_for(site)
      # Just return the defaults for now, in the future we can
      # offer per-site discounts, etc
      return self.defaults
    end
  end

  def values
    self.class.values_for(site).merge(schedule: schedule)
  end

  def pending_bills(reload=false)
    self.bills(reload).reject{|b| b.status != :pending}
  end

  def paid_bills(reload=false)
    self.bills(reload).reject{|b| b.status != :paid}
  end

  def active_bills(reload=false, date=nil)
    date ||= Time.now
    self.bills(reload).reject{|b| !b.active_during(date)}
  end

  def capabilities(reload=false)
    if reload || !@capabilities
      # If we are in good standing we just return our normal
      # capabilities, otherwise we return the default capabilities
      active_bills(reload).each do |bill|
        payment_method = nil
        if self.site and self.site.current_subscription and self.site.current_subscription.payment_method
          payment_method = self.site.current_subscription.payment_method
        end
        if bill.problem_with_payment?(payment_method)
          @capabilities = ProblemWithPayment::Capabilities.new(self, self.site)
          return @capabilities
        end
      end
      @capabilities = self.class::Capabilities.new(self, self.site)
    end
    @capabilities
  end

  after_initialize :set_initial_values
  def set_initial_values
    unless self.persisted?
      values = self.class.values_for(self.site)
      self.amount ||= self.monthly? ? values[:monthly_amount] : values[:yearly_amount]
      self.visit_overage ||= values[:visit_overage]
      self.visit_overage_unit ||= values[:visit_overage_unit]
      self.visit_overage_amount ||= values[:visit_overage_amount]
    end
  end

  class Capabilities
    def initialize(subscription, site)
      @subscription = subscription
      @site = site
    end

    def remove_branding?
      false
    end

    def custom_targeted_bars?
      false
    end

    def custom_thank_you_text?
      false
    end

    def max_suggestions
      3
    end

    def activate_on_exit?
      false
    end

    def max_site_elements
      10
    end

    def at_site_element_limit?
      @site.site_elements.size >= max_site_elements
    end

    def num_days_improve_data
      90
    end

    def visit_overage
      @subscription ? @subscription.visit_overage : parent_class.values_for(@site)[:visit_overage]
    end

    def visit_overage_unit
      @subscription ? @subscription.visit_overage_unit : parent_class.values_for(@site)[:visit_overage_unit]
    end

    def visit_overage_amount
      @subscription ? @subscription.visit_overage_amount : parent_class.values_for(@site)[:visit_overage_amount]
    end

    protected

    def parent_class
      self.class.parent
    end
  end

  class Free < self
    class Capabilities < Subscription::Capabilities
    end

    class << self
      def defaults
        {
          name: "Free",
          monthly_amount: 0.0,
          yearly_amount: 0.0,
          visit_overage: 25_000, # after this many visits in a month
          visit_overage_amount: 10, # every X visitors
          visit_overage_amount: nil # ads
        }
      end
    end
  end

  class FreePlus < Free
    class Capabilities < Free::Capabilities
      def max_site_elements
        1.0 / 0.0 # infinity
      end
    end

    class << self
      def defaults
        {
          name: "Free Plus",
          monthly_amount: 0.0,
          yearly_amount: 0.0,
          visit_overage: 25_000, # after this many visits in a month
          visit_overage_amount: 10, # every X visitors
          visit_overage_amount: nil # ads
        }
      end
    end
  end

  # These are the capabilities of a user who has an issue with payment
  # They are basically the same as Free, but we don't let the subscription
  # override the visit_overage features
  class ProblemWithPayment < Free
    class Capabilities < Free::Capabilities
      def visit_overage
        parent_class.values_for(@site)[:visit_overage]
      end

      def visit_overage_unit
        parent_class.values_for(@site)[:visit_overage_unit]
      end

      def visit_overage_amount
        parent_class.values_for(@site)[:visit_overage_amount]
      end
    end
  end

  class Pro < Free
    class Capabilities < Free::Capabilities
      def remove_branding?
        true
      end

      def custom_targeted_bars?
        true
      end

      def custom_thank_you_text?
        true
      end

      def max_suggestions
        10
      end

      def activate_on_exit?
        true
      end

      def max_site_elements
        1.0 / 0.0 # infinity
      end

      def num_days_improve_data
        365
      end
    end

    class << self
      def defaults
        {
          name: "Pro",
          monthly_amount: 15.0,
          yearly_amount: 149.0,
          visit_overage: 250_000, # after this many visits in a month
          visit_overage_amount: 25_000, # every X visitors
          visit_overage_amount: 5.00 # $$$
        }
      end
    end
  end

  class ProComped < Pro
    class << self
      def defaults
        {
          name: "Pro Comped",
          monthly_amount: 0.0,
          yearly_amount: 0.0,
          visit_overage: 250_000, # after this many visits in a month
          visit_overage_amount: 25_000, # every X visitors
          visit_overage_amount: 0.0 # $$$
        }
      end
    end
  end

  class Enterprise < Pro
    class Capabilities < Pro::Capabilities
    end

    class << self
      def defaults
        {
          name: "Enterprise",
          monthly_amount: 99.0,
          yearly_amount: 999.0,
          visit_overage: nil, # unlimited
          visit_overage_amount: nil, # unlimited
          visit_overage_amount: nil # unlimited
        }
      end
    end
  end

  def <=>(other)
    if other.is_a?(Subscription)
      return Comparison.new(self, other).direction
    else
      super(other)
    end
  end

  # These need to be in the order of least expensive to most expensive
  PLANS = [Free, Pro, Enterprise]
  class Comparison
    attr_reader :from_subscription, :to_subscription, :direction
    def initialize(from_subscription, to_subscription)
      @from_subscription, @to_subscription = from_subscription, to_subscription
      from_index = to_index = nil
      PLANS.each_with_index do |plan, index|
        from_index = index if from_subscription.is_a?(plan)
        to_index = index if to_subscription.is_a?(plan)
      end
      raise "Could not find plans (from_subscription: #{from_subscription.inspect} and to_subscription: #{to_subscription.inspect}, got #{from_index.inspect} and #{to_index.inspect}" unless from_index and to_index
      if from_index == to_index
        @direction = 0
      elsif from_index > to_index
        @direction = -1
      else
        @direction = 1
      end
    end

    def upgrade?
      @direction > 0
    end

    def downgrade?
      !upgrade?
    end

    def same_plan?
      @direction == 0
    end
  end
end
