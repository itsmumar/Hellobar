class Subscription
  class ProSpecial < Subscription
    autoload :Capabilities, 'subscription/pro_special/capabilities'

    class << self
      def defaults
        {
          type: 'pro_special',
          name: 'Pro Special',
          label: 'PSP',
          monthly_amount: 1.0,
          yearly_amount: 149.0,
          visit_warning_one: 40_000,
          visit_warning_two: ::Float::INFINITY,
          visit_warning_three: ::Float::INFINITY,
          visit_overage: 50_000,
          visit_overage_amount: 5.00, # $$$
          upsell_email_trigger: 300_000,
          upgrade_trigger: 400_000
        }
      end
    end

    def dme?
      created_at > DME_TRIAL_PERIOD.ago
    end
  end
end
