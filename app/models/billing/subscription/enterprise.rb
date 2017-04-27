class Subscription
  class Enterprise < Base
    def significance
      50
    end

    class Capabilities < Pro::Capabilities
    end

    class << self
      def defaults
        {
          name: 'Enterprise',
          monthly_amount: 99.0,
          yearly_amount: 999.0,
          visit_overage: nil, # unlimited
          # visit_overage_amount: nil, # unlimited
          visit_overage_amount: nil # unlimited
        }
      end
    end
  end
end
