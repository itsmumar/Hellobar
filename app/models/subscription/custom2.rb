class Subscription
  class Custom2 < Subscription
    autoload :Capabilities, 'subscription/custom_2/capabilities'

    class << self
      def defaults
        {
          type: 'custom_2',
          name: 'Custom 2',
          label: 'CU2',
          monthly_amount: 299.0,
          yearly_amount: 2990.0,
          visit_overage: 10_000_000,
          visit_warning_one: 8_000_000,
          visit_warning_two: ::Float::INFINITY,
          visit_warning_three: ::Float::INFINITY,
          visit_overage_amount: 5.00,
          upsell_email_trigger: 20_000_000,
          upgrade_trigger: ::Float::INFINITY
        }
      end
    end

    def dme?
      true
    end
  end
end
