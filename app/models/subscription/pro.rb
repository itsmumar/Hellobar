class Subscription
  class Pro < Subscription
    autoload :Capabilities, 'subscription/pro/capabilities'

    class << self
      def defaults
        {
          type: 'pro',
          name: 'Pro',
          label: 'PRO',
          monthly_amount: 29.0,
          yearly_amount: 289.0,
          visit_warning_one: 40_000,
          visit_warning_two: ::Float::INFINITY,
          visit_warning_three: ::Float::INFINITY,
          visit_overage: 50_000, # after this many visits in a month
          visit_overage_amount: 5.00, # $$$
          upsell_email_trigger: 300_000, # Send the email saying they should upgrade to save
          upgrade_trigger: 400_000,
          discounts: [
            DiscountRange.new(5, 0, 0, 0),
            DiscountRange.new(5, 1, 4, 40),
            DiscountRange.new(10, 2, 8, 80),
            DiscountRange.new(10, 3, 12, 120),
            DiscountRange.new(nil, 4, 16, 160)
          ]
        }
      end
    end

    def dme?
      created_at > DME_TRIAL_PERIOD.ago
    end
  end
end
