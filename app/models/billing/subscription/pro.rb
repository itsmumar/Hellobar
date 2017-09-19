class Subscription
  class Pro < Base
    class Capabilities < Free::Capabilities
      def acts_as_paid_subscription?
        true
      end

      def remove_branding?
        true
      end

      def closable?
        true
      end

      def custom_targeted_bars?
        true
      end

      def custom_thank_you_text?
        true
      end

      def after_submit_redirect?
        true
      end

      def activate_on_exit?
        true
      end

      def max_site_elements
        Float::INFINITY
      end

      def num_days_improve_data
        365
      end
    end

    class << self
      def defaults
        {
          name: 'Pro',
          label: 'PRO',
          monthly_amount: 15.0,
          yearly_amount: 149.0,
          visit_overage: 250_000, # after this many visits in a month
          # visit_overage_amount: 25_000, # every X visitors
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
