class Subscription
  class Elite < Subscription
    autoload :Capabilities, 'subscription/elite/capabilities'

    class << self
      def defaults
        {
          type: 'elite',
          name: 'Elite',
          label: 'ENT',
          monthly_amount: 99.0,
          yearly_amount: 999.0,
          visit_overage: 500_000,
          visit_warning_one: 400_000,
          visit_warning_two: ::Float::INFINITY,
          visit_warning_three: ::Float::INFINITY,
          visit_overage_amount: nil,
          upsell_email_trigger: 1_000_000
        }
      end
    end
  end
end
