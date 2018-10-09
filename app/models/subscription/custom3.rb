class Subscription
  class Custom3 < Subscription
    autoload :Capabilities, 'subscription/custom_3/capabilities'

    class << self
      def defaults
        {
          type: 'custom_3',
          name: 'Custom 3',
          label: 'CU3',
          monthly_amount: 399.0,
          yearly_amount: 3990.0,
          visit_overage: 20_000_000,
          visit_warning_one: 17_000_000,
          visit_warning_two: ::Float::INFINITY,
          visit_warning_three: ::Float::INFINITY,
          visit_overage_amount: 5.00,
          upsell_email_trigger: 40_000_000
        }
      end
    end
  end
end
