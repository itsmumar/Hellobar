class Subscription
  class EliteSpecial < Subscription
    autoload :Capabilities, 'subscription/elite_special/capabilities'

    class << self
      def defaults
        {
          type: 'elite_special',
          name: 'Elite Special',
          label: 'ESP',
          monthly_amount: 99.0,
          yearly_amount: 799.0,
          visit_overage: 500_000,
          visit_warning_one: 400_000,
          visit_warning_two: ::Float::INFINITY,
          visit_warning_three: ::Float::INFINITY,
          visit_overage_amount: 5.00,
          upsell_email_trigger: 1_000_000
        }
      end
    end

    def dme?
      true
    end
  end
end
