class Subscription
  class FreePlus < Free
    class Capabilities < Free::Capabilities
      def max_site_elements
        Float::INFINITY
      end
    end

    class << self
      def defaults
        {
          name: 'Free Plus',
          monthly_amount: 0.0,
          yearly_amount: 0.0,
          visit_overage: 25_000, # after this many visits in a month
          # visit_overage_amount: 10, # every X visitors
          visit_overage_amount: nil # ads
        }
      end
    end
  end
end
