class Subscription
  class Enterprise < Subscription
    autoload :Capabilities, 'subscription/enterprise/capabilities'

    class << self
      def defaults
        {
          type: 'enterprise',
          name: 'Enterprise',
          label: 'ENT',
          monthly_amount: 99.0,
          yearly_amount: 999.0,
          visit_overage: 500_000,
          visit_warning_one: 400_000,
          visit_warning_two: ::Float::INFINITY,
          visit_warning_three: ::Float::INFINITY,
          visit_overage_amount: nil
        }
      end
    end
  end
end
