require 'billing_log'

class Subscription < ActiveRecord::Base
  include BillingAuditTrail
  belongs_to :user
  belongs_to :site
  enum schedule: [:monthly, :yearly]
  has_many :bills, ->{order "id"}

  def pending_bills(reload=false)
    self.bills(reload).reject{|b| b.status != :pending}
  end

  def paid_bills(reload=false)
    self.bills(reload).reject{|b| b.status != :paid}
  end

  def active_bills(reload=false, date=nil)
    date ||= Time.now
    self.bills(reload).reject{|b| b.voided? || !b.start_date || !b.end_date || b.start_date > date || b.end_date < date}
  end

  def capabilities
    unless @capabilities
      # If we are in good standing we just return our normal
      # capabilities, otherwise we return the default capabilities
      @capabilities = self.class::Capabilities.new(self, self.site)
    end
    @capabilities
  end

  before_create :set_defaults
  def set_defaults
    defaults = self.class.defaults
    self.amount ||= self.monthly? ? defaults[:monthly_amount] : defaults[:yearly_amount]
    self.visit_overage ||= defaults[:visit_overage]
    self.visit_overage_unit ||= defaults[:visit_overage_unit]
    self.visit_overage_amount ||= defaults[:visit_overage_amount]
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
    
    def max_suggestions
      3
    end

    def activate_on_exit?
      false
    end

    def max_rules
      10
    end

    def num_days_improve_data
      90
    end

    def visit_overage
      @subscription ? @subscription.visit_overage : parent_class.defaults[:visit_overage]
    end

    def visit_overage_unit
      @subscription ? @subscription.visit_overage_unit : parent_class.defaults[:visit_overage_unit]
    end

    def visit_overage_amount
      @subscription ? @subscription.visit_overage_amount : parent_class.defaults[:visit_overage_amount]
    end

    protected
    # Is there a better way?
    def parent_class
      Kernel.const_get(self.class.name.split("::")[0...-1].join("::"))
    end
  end

  class Free < self
    class Capabilities < Subscription::Capabilities
    end

    class << self
      def defaults
        {
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
        puts "-"*80
        parent_class.defaults[:visit_overage]
      end

      def visit_overage_unit
        parent_class.defaults[:visit_overage_unit]
      end

      def visit_overage_amount
        parent_class.defaults[:visit_overage_amount]
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

      def max_suggestions
        10
      end

      def activate_on_exit?
        true
      end

      def max_rules
        false
      end

      def num_days_improve_data
        365
      end
    end

    class << self
      def defaults
        {
          monthly_amount: 15.0,
          yearly_amount: 149.0,
          visit_overage: 250_000, # after this many visits in a month
          visit_overage_amount: 25_000, # every X visitors
          visit_overage_amount: 5.00 # $$$
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
          monthly_amount: 99.0,
          yearly_amount: 999.0,
          visit_overage: nil, # unlimited
          visit_overage_amount: nil, # unlimited
          visit_overage_amount: nil # unlimited
        }
      end
    end
  end

  PLANS = [Free, Pro, Enterprise]
end
