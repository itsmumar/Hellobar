class Subscription
  class Pro < Subscription
    autoload :Capabilities, 'subscription/pro/capabilities'

    class << self
      def defaults
        {
          type: 'pro',
          name: 'Pro',
          label: 'PRO',
          monthly_amount: 15.0,
          yearly_amount: 149.0,
          visit_overage: 50_000,
          visit_overage_amount: 5.00, # $$$
          discounts: [
            DiscountRange.new(5, 0, 0, 0),
            DiscountRange.new(5, 1, 2, 20),
            DiscountRange.new(10, 2, 4, 40),
            DiscountRange.new(10, 3, 6, 60),
            DiscountRange.new(nil, 4, 8, 80)
          ]
        }
      end
    end
  end
end
