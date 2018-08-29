class Subscription
  class ProComped < Subscription
    autoload :Capabilities, 'subscription/pro_comped/capabilities'

    class << self
      def defaults
        {
          type: 'pro_comped',
          name: 'Pro Comped',
          label: 'CMP',
          monthly_amount: 0.0,
          yearly_amount: 0.0,
          visit_warning_one: 40_000,
          visit_warning_two: ::Float::INFINITY,
          visit_warning_three: ::Float::INFINITY,
          visit_overage: 50_000, # after this many visits in a month
          visit_overage_amount: 0.0, # $$$
          upsell_email_trigger: ::Float::INFINITY
        }
      end
    end
  end
end
