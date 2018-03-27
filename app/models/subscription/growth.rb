class Subscription
  class Growth < Pro
    autoload :Capabilities, 'subscription/pro/capabilities'

    class << self
      def defaults
        {
          type: 'growth',
          name: 'Growth',
          label: 'GROWTH',
          monthly_amount: 29.0,
          yearly_amount: 289.0,
          visit_overage: 250_000, # after this many visits in a month
          # visit_overage_amount: 25_000, # every X visitors
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
