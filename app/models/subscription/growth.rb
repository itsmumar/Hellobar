class Subscription
  class Growth < Pro
    autoload :Capabilities, 'subscription/growth/capabilities'

    class << self
      def defaults
        {
          type: 'growth',
          name: 'Growth',
          label: 'GRW',
          monthly_amount: 29.0,
          yearly_amount: 289.0,
          visit_warning_one: 40_000,
          visit_overage: 50_000,
          visit_overage_amount: 5.00, # $$$
          discounts: [ # discounts are doubled from Pro
            DiscountRange.new(5, 0, 0, 0),
            DiscountRange.new(5, 1, 4, 40),
            DiscountRange.new(10, 2, 8, 80),
            DiscountRange.new(10, 3, 12, 120),
            DiscountRange.new(nil, 4, 16, 160)
          ]
        }
      end
    end
  end
end
