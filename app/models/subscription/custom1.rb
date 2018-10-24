class Subscription
  class Custom1 < Subscription
    autoload :Capabilities, 'subscription/custom_1/capabilities'

    class << self
      def defaults
        {
          type: 'custom_1',
          name: 'Custom 1',
          label: 'CU1',
          monthly_amount: 199.0,
          yearly_amount: 1990.0,
          visit_overage: 5_000_000,
          visit_warning_one: 4_000_000,
          visit_warning_two: ::Float::INFINITY,
          visit_warning_three: ::Float::INFINITY,
          visit_overage_amount: 5.00,
          upsell_email_trigger: 10_000_000
        }
      end
    end

    def dme?
      true
    end
  end
end
