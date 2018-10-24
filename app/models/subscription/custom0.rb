class Subscription
  class Custom0 < Subscription
    autoload :Capabilities, 'subscription/custom_0/capabilities'

    class << self
      def defaults
        {
          type: 'custom_0',
          name: 'Custom 0',
          label: 'CU0',
          monthly_amount: 149.0,
          yearly_amount: 1490.0,
          visit_overage: 2_000_000,
          visit_warning_one: 1_000_000,
          visit_warning_two: ::Float::INFINITY,
          visit_warning_three: ::Float::INFINITY,
          visit_overage_amount: 5.00,
          upsell_email_trigger: 4_000_000
        }
      end
    end
  end
end
