class Subscription
  class Free < Subscription
    def free?
      true
    end

    class Capabilities < Subscription::Capabilities
    end

    class << self
      def defaults
        {
          name: 'Free',
          label: 'FREE',
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
